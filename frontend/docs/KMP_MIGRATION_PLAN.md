# KMP Migration Plan: UseCase Layer and Below

## Overview

iOS実装済みのMemoriesアプリをKMP (Kotlin Multiplatform)で共通化する計画。
**プラットフォームに依存しないロジック**をKotlinで共通化し、
**プラットフォーム固有API**（SwiftData, Keychain等）は小さなAdapterとしてDIする。

## Current Architecture (iOS)

```
┌─────────────────────────────────────┐
│     UIComponents (SwiftUI)          │  ← Platform-specific (keep)
├─────────────────────────────────────┤
│     UILogics (MVVM ViewModels)      │  ← Platform-specific (keep)
├─────────────────────────────────────┤
│     UseCases (Business Logic)       │  ← KMP (Kotlin実装)
├─────────────────────────────────────┤
│     APIGateways (API Facade)        │  ← KMP (Kotlin実装)
├─────────────────────────────────────┤
│     Repositories (Data Layer)       │  ← KMP (ロジック共通化 + Adapter DI)
├─────────────────────────────────────┤
│     APIClients (HTTP)               │  ← KMP (Ktor)
├─────────────────────────────────────┤
│     Domains (Models)                │  ← KMP (Kotlin実装)
└─────────────────────────────────────┘
```

---

## Naming Conventions

**Kotlinスタイルの命名規則を採用（`Protocol`サフィックスなし）:**

| Type | Naming | Example |
|------|--------|---------|
| Interface | 名詞 | `AlbumRepository`, `SecureStorage` |
| 実装クラス | `Impl`サフィックス | `AlbumRepositoryImpl`, `AuthSessionRepositoryImpl` |
| Bridge Interface | `Bridge`サフィックス | `AlbumRepositoryBridge` |
| Bridge実装 | `BridgeImpl`サフィックス | `AlbumRepositoryBridgeImpl` |
| UseCase | 動詞+UseCase | `AlbumListUseCase`, `LoginUseCase` |
| Gateway | 名詞+Gateway | `AlbumGateway`, `AuthGateway` |

---

## Implementation Strategy

### 方針: ロジックを共通化、PF固有APIはAdapter経由でDI

| Layer | Implementation | Notes |
|-------|---------------|-------|
| Domains | **Kotlin共通化** | 純粋なdata class |
| APIClients | **Kotlin共通化** | Ktor HttpClient |
| APIGateways | **Kotlin共通化** | ビジネスロジックなし |
| Repositories | **Kotlin共通化** | PF固有APIはAdapter経由 |
| UseCases | **Kotlin共通化** | 純粋なビジネスロジック |

### Repository実装方針

| Repository | 実装 | Adapter |
|------------|------|---------|
| AlbumRepository | **Bridge経由** | SwiftData/Room依存のためBridge |
| MemoryRepository | **Bridge経由** | SwiftData/Room依存のためBridge |
| UserRepository | **Bridge経由** | SwiftData/Room依存のためBridge |
| SyncQueueRepository | **Bridge経由** | SwiftData/Room依存のためBridge |
| AuthSessionRepository | **Kotlin共通化** | SecureStorage adapter |
| ImageStorageRepository | **Kotlin共通化** | FileStorage adapter |
| ReachabilityRepository | **Kotlin共通化** | NetworkMonitor adapter |

---

## Adapter Pattern Example

### AuthSessionRepository

**ロジックはKotlinで共通化、Keychain/EncryptedSharedPreferencesはAdapterでDI:**

```kotlin
// commonMain - Adapter interface
interface SecureStorage {
    fun getString(key: String): String?
    fun putString(key: String, value: String)
    fun remove(key: String)
}

// commonMain - Repository実装（ロジック共通化）
class AuthSessionRepositoryImpl(
    private val secureStorage: SecureStorage
) : AuthSessionRepository {

    private val _sessionFlow = MutableStateFlow<AuthSession?>(null)

    override fun restore(): AuthSession? {
        val token = secureStorage.getString(KEY_TOKEN) ?: return null
        val userId = secureStorage.getString(KEY_USER_ID)?.toIntOrNull() ?: return null
        val session = AuthSession(token, userId)
        _sessionFlow.value = session
        return session
    }

    override fun save(session: AuthSession) {
        secureStorage.putString(KEY_TOKEN, session.token)
        secureStorage.putString(KEY_USER_ID, session.userId.toString())
        _sessionFlow.value = session
    }

    override fun clearSession() {
        secureStorage.remove(KEY_TOKEN)
        secureStorage.remove(KEY_USER_ID)
        _sessionFlow.value = null
    }

    @NativeCoroutines
    override fun getSessionFlow(): Flow<AuthSession?> = _sessionFlow.asStateFlow()

    companion object {
        private const val KEY_TOKEN = "auth_token"
        private const val KEY_USER_ID = "user_id"
    }
}
```

```swift
// iOS - Keychain Adapter
class KeychainSecureStorage: SecureStorage {
    private let keychain = Keychain(service: "com.example.memoriesapp")

    func getString(key: String) -> String? {
        try? keychain.get(key)
    }

    func putString(key: String, value: String) {
        try? keychain.set(value, key: key)
    }

    func remove(key: String) {
        try? keychain.remove(key)
    }
}
```

### ReachabilityRepository

```kotlin
// commonMain - Adapter interface
interface NetworkMonitor {
    val isConnected: Boolean
    val isConnectedFlow: Flow<Boolean>
}

// commonMain - Repository実装
class ReachabilityRepositoryImpl(
    private val networkMonitor: NetworkMonitor
) : ReachabilityRepository {
    override val isConnected: Boolean get() = networkMonitor.isConnected

    @NativeCoroutines
    override val isConnectedFlow: Flow<Boolean> = networkMonitor.isConnectedFlow
}
```

```swift
// iOS - NWPathMonitor Adapter
class NWPathMonitorAdapter: NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let _isConnectedSubject = CurrentValueSubject<Bool, Never>(true)

    var isConnected: Bool { _isConnectedSubject.value }
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        _isConnectedSubject.eraseToAnyPublisher()
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?._isConnectedSubject.send(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }
}
```

### ImageStorageRepository

```kotlin
// commonMain - Adapter interface
interface FileStorage {
    fun write(path: String, data: ByteArray)
    fun read(path: String): ByteArray
    fun delete(path: String)
    fun exists(path: String): Boolean
    val basePath: String
}

// commonMain - Repository実装
class ImageStorageRepositoryImpl(
    private val fileStorage: FileStorage
) : ImageStorageRepository {

    override fun save(data: ByteArray, entity: ImageEntityType, localId: LocalId): String {
        val path = getPath(entity, localId)
        fileStorage.write(path, data)
        return path
    }

    override fun get(entity: ImageEntityType, localId: LocalId): ByteArray {
        val path = getPath(entity, localId)
        if (!fileStorage.exists(path)) throw ImageStorageError.FileNotFound
        return fileStorage.read(path)
    }

    override fun delete(entity: ImageEntityType, localId: LocalId) {
        fileStorage.delete(getPath(entity, localId))
    }

    override fun getPath(entity: ImageEntityType, localId: LocalId): String {
        return "${fileStorage.basePath}/${entity.directory}/${localId}.jpg"
    }
}
```

---

## Current iOS Module Structure

| Module | Files | Description |
|--------|-------|-------------|
| Domains | 8 | 純粋なドメインモデル (Album, Memory, User, etc.) |
| APIClients | 17 | HTTP通信の低レベルAPI (URLSession) |
| APIGateways | 14 | APIClientをラップしてレスポンスをデコード |
| Repositories | 21 | ローカルDB (SwiftData) とキャッシュ管理 |
| UseCases | 22+ | ビジネスロジック |
| UILogics | 8+ | ViewModels |
| UIComponents | Multiple | SwiftUI Views |

---

## Phase 1: Foundation Layer (Domains)

### 1.1 Core Types

| Swift Type | Kotlin Type | Notes |
|------------|-------------|-------|
| `UUID` | `LocalId` (kotlin.uuid.Uuid wrapper) | Platform UUID wrapper |
| `Date` | `Timestamp` (kotlinx-datetime Instant) | Epoch milliseconds based |
| `URL` | `String` | Convert at edges |
| `Data` | `ByteArray` | Binary data |

**Files to create:**
```
shared/src/commonMain/kotlin/com/example/memoriesapp/
└── core/
    ├── LocalId.kt
    ├── Timestamp.kt
    └── SyncStatus.kt
```

### 1.2 Domain Models

**Files to create:**
```
shared/src/commonMain/kotlin/com/example/memoriesapp/
└── domain/
    ├── Album.kt
    ├── Memory.kt
    ├── User.kt
    ├── AuthSession.kt
    ├── SyncOperation.kt
    ├── MimeType.kt
    └── OptionalUpdate.kt
```

---

## Phase 2: Network Layer (APIClients)

### 2.1 Structure

```
shared/src/commonMain/kotlin/com/example/memoriesapp/
└── api/
    ├── client/
    │   ├── ApiClient.kt              (interface)
    │   ├── ApiClientImpl.kt          (Ktor implementation)
    │   └── AuthenticatedApiClient.kt
    ├── request/
    │   ├── LoginRequest.kt
    │   ├── GetAlbumsRequest.kt
    │   ├── AlbumCreateRequest.kt
    │   └── ... (11 requests total)
    ├── response/
    │   ├── TokenResponse.kt
    │   ├── AlbumResponse.kt
    │   ├── PaginatedAlbumsResponse.kt
    │   └── ... (6 responses total)
    └── error/
        └── ApiError.kt
```

---

## Phase 3: API Facade (APIGateways)

### 3.1 Structure

```
shared/src/commonMain/kotlin/com/example/memoriesapp/
└── gateway/
    ├── AuthGateway.kt
    ├── AlbumGateway.kt
    ├── MemoryGateway.kt
    └── UserGateway.kt
```

---

## Phase 4: Data Layer (Repositories)

### 4.1 Structure

```
shared/src/commonMain/kotlin/com/example/memoriesapp/
└── repository/
    ├── AlbumRepository.kt              (interface)
    ├── MemoryRepository.kt             (interface)
    ├── UserRepository.kt               (interface)
    ├── SyncQueueRepository.kt          (interface)
    ├── AuthSessionRepository.kt        (interface)
    ├── AuthSessionRepositoryImpl.kt    (Kotlin実装)
    ├── ImageStorageRepository.kt       (interface)
    ├── ImageStorageRepositoryImpl.kt   (Kotlin実装)
    ├── ReachabilityRepository.kt       (interface)
    └── ReachabilityRepositoryImpl.kt   (Kotlin実装)
```

### 4.2 Adapters (Platform-specific)

```
shared/src/commonMain/kotlin/com/example/memoriesapp/
└── adapter/
    ├── SecureStorage.kt      (interface)
    ├── FileStorage.kt        (interface)
    └── NetworkMonitor.kt     (interface)
```

### 4.3 SwiftData依存Repository (Bridge経由)

**SwiftData依存のRepositoryはBridge経由で接続:**

```kotlin
// commonMain - Interface
interface AlbumRepository {
    suspend fun getAll(): List<Album>
    suspend fun getByLocalId(localId: LocalId): Album?
    suspend fun getByServerId(serverId: Int): Album?
    suspend fun syncSet(albums: List<Album>)
    suspend fun syncAppend(albums: List<Album>)
    suspend fun insert(album: Album)
    suspend fun update(album: Album)
    suspend fun delete(localId: LocalId)
    suspend fun markAsSynced(localId: LocalId, serverId: Int)
    suspend fun updateCoverImageUrl(localId: LocalId, url: String)

    @NativeCoroutines
    val localChangeFlow: Flow<LocalAlbumChangeEvent>
}
```

```swift
// iOS - SwiftData実装をBridge経由で接続
class AlbumRepositoryBridgeImpl: AlbumRepositoryBridge {
    private let swiftDataRepository: AlbumRepository  // 既存SwiftData実装
    // ...
}
```

---

## Phase 5: Business Logic (UseCases)

### 5.1 Structure

```
shared/src/commonMain/kotlin/com/example/memoriesapp/
└── usecase/
    ├── LoginUseCase.kt
    ├── AlbumListUseCase.kt
    ├── AlbumDetailUseCase.kt
    ├── AlbumFormUseCase.kt
    ├── MemoryFormUseCase.kt
    ├── UserProfileUseCase.kt
    ├── SyncQueuesUseCase.kt
    ├── RootUseCase.kt
    ├── SplashUseCase.kt
    ├── model/
    │   ├── DeepLink.kt
    │   └── SyncQueueItem.kt
    ├── mapper/
    │   ├── AlbumMapper.kt
    │   ├── UserMapper.kt
    │   └── MemoryMapper.kt
    └── service/
        └── SyncQueueService.kt
```

### 5.2 Combine → Flow Migration

| Combine Pattern | Kotlin Flow Pattern |
|-----------------|---------------------|
| `AnyPublisher<T, Never>` | `Flow<T>` |
| `PassthroughSubject<T, Never>` | `MutableSharedFlow<T>()` |
| `CurrentValueSubject<T, Never>` | `MutableStateFlow<T>(initial)` |
| `.sink { }` | `.collect { }` |
| `.receive(on: DispatchQueue.main)` | `.flowOn(Dispatchers.Main)` |
| `Publishers.Merge(a, b)` | `merge(a, b)` |
| `.eraseToAnyPublisher()` | `.asSharedFlow()` / `.asStateFlow()` |

### 5.3 UseCase Example with @NativeCoroutines

```kotlin
class AlbumListUseCase(
    private val albumRepository: AlbumRepository,
    private val albumGateway: AlbumGateway,
    private val userRepository: UserRepository,
    private val syncQueueRepository: SyncQueueRepository,
    private val syncQueueService: SyncQueueService,
    private val reachabilityRepository: ReachabilityRepository
) {
    @NativeCoroutines
    fun observeUser(): Flow<User> = userRepository.userFlow

    @NativeCoroutines
    fun observeAlbumChange(): Flow<LocalAlbumChangeEvent> =
        albumRepository.localChangeFlow

    @NativeCoroutines
    fun observeSync(): Flow<SyncQueueState> = merge(
        syncQueueRepository.stateFlow,
        reachabilityRepository.isConnectedFlow
            .distinctUntilChanged()
            .filter { it }
            .onEach { syncQueueService.processQueue() }
            .flatMapLatest { emptyFlow() }
    )

    @NativeCoroutineScope
    suspend fun display(): DisplayResult { /* ... */ }

    @NativeCoroutineScope
    suspend fun next(page: Int): NextResult { /* ... */ }
}
```

---

## KMP-NativeCoroutines Configuration

### Overview

KMP-NativeCoroutinesを使用してKotlin Flow/suspend関数をSwift Combine/async-awaitに変換。

### Kotlin側の使い方

```kotlin
// Flow → Swift (Combine or AsyncSequence)
@NativeCoroutines
fun observeAlbumChange(): Flow<LocalAlbumChangeEvent>

// suspend関数 → Swift async
@NativeCoroutineScope
suspend fun display(): DisplayResult
```

### Swift側の使い方

**Combine (既存ViewModelとの互換性):**
```swift
@MainActor
class AlbumListViewModel: ObservableObject {
    private let useCase: AlbumListUseCase
    private var cancellables = Set<AnyCancellable>()

    func startObserving() {
        // Flow → AnyPublisher
        createPublisher(for: useCase.observeAlbumChange())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleLocalChange(event)
            }
            .store(in: &cancellables)

        createPublisher(for: useCase.observeUser())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.updateUserIcon(user)
            }
            .store(in: &cancellables)
    }

    func display() {
        Task {
            // suspend → async
            let result = try await asyncFunction(for: useCase.display())
            await MainActor.run {
                self.handleDisplayResult(result)
            }
        }
    }
}
```

**AsyncSequence (Swift Concurrency):**
```swift
@MainActor
class AlbumListViewModel: ObservableObject {
    private let useCase: AlbumListUseCase
    private var observeTask: Task<Void, Never>?

    func startObserving() {
        observeTask = Task {
            // Flow → AsyncSequence
            for try await event in asyncSequence(for: useCase.observeAlbumChange()) {
                handleLocalChange(event)
            }
        }
    }

    deinit {
        observeTask?.cancel()
    }
}
```

---

## iOS Integration Strategy

### Step 1: KMP Framework Build

```bash
./gradlew :shared:embedAndSignAppleFrameworkForXcode
```

### Step 2: Swift Package Manager Setup

```swift
// Package.swift に追加
dependencies: [
    .package(url: "https://github.com/nickclephas/KMP-NativeCoroutines", from: "1.0.0-ALPHA-36")
]
```

### Step 3: DI Setup

```swift
// AppContainer.swift
class AppContainer {
    // Adapters
    lazy var secureStorage: SecureStorage = KeychainSecureStorage()
    lazy var fileStorage: FileStorage = iOSFileStorage()
    lazy var networkMonitor: NetworkMonitor = NWPathMonitorAdapter()

    // Repositories (Kotlin実装 + Adapter DI)
    lazy var authSessionRepository: AuthSessionRepository =
        AuthSessionRepositoryImpl(secureStorage: secureStorage)
    lazy var imageStorageRepository: ImageStorageRepository =
        ImageStorageRepositoryImpl(fileStorage: fileStorage)
    lazy var reachabilityRepository: ReachabilityRepository =
        ReachabilityRepositoryImpl(networkMonitor: networkMonitor)

    // Repositories (Bridge経由)
    lazy var albumRepository: AlbumRepository =
        AlbumRepositoryBridge(bridge: AlbumRepositoryBridgeImpl(swiftDataRepository))
    // ...
}
```

### Step 4: ViewModel Migration

```swift
// Before: Swift UseCase + Combine
class AlbumListViewModel: ObservableObject {
    private let useCase: AlbumListUseCaseProtocol  // Swift
    private var cancellables = Set<AnyCancellable>()

    func startObserving() {
        useCase.observeAlbumChange()
            .sink { ... }
            .store(in: &cancellables)
    }
}

// After: KMP UseCase + KMP-NativeCoroutines (Combine互換)
class AlbumListViewModel: ObservableObject {
    private let useCase: AlbumListUseCase  // KMP
    private var cancellables = Set<AnyCancellable>()

    func startObserving() {
        createPublisher(for: useCase.observeAlbumChange())
            .receive(on: DispatchQueue.main)
            .sink { ... }
            .store(in: &cancellables)
    }
}
```

---

## Directory Structure After Migration

```
frontend/
├── shared/
│   └── src/
│       └── commonMain/kotlin/com/example/memoriesapp/
│           ├── core/           (LocalId, Timestamp, SyncStatus)
│           ├── domain/         (Album, Memory, User, etc.)
│           ├── api/            (Ktor client, requests, responses)
│           ├── gateway/        (AlbumGateway, etc.)
│           ├── adapter/        (SecureStorage, FileStorage, NetworkMonitor)
│           ├── repository/     (interfaces + Kotlin実装)
│           └── usecase/        (business logic)
│
├── composeApp/                  (Android UI - future)
│
└── iosApp/                      (iOS UI)
    ├── iosApp/                  (App entry + DI)
    ├── Adapters/                (Keychain, FileManager, NWPathMonitor adapters)
    ├── KMPBridge/               (SwiftData Repository bridges)
    ├── UILogics/                (ViewModels - consume KMP)
    ├── UIComponents/            (SwiftUI views)
    ├── Repositories/            (SwiftData実装は維持)
    └── Utilities/               (維持)
```

---

## Migration Order

```
Phase 1: Domains (Kotlin共通化)
  ├── core/LocalId.kt
  ├── core/Timestamp.kt
  ├── core/SyncStatus.kt
  ├── domain/Album.kt
  ├── domain/Memory.kt
  ├── domain/User.kt
  ├── domain/AuthSession.kt
  ├── domain/SyncOperation.kt
  ├── domain/MimeType.kt
  └── domain/OptionalUpdate.kt

Phase 2: APIClients (Kotlin共通化 - Ktor)
  ├── api/error/ApiError.kt
  ├── api/client/ApiClient.kt
  ├── api/client/ApiClientImpl.kt
  ├── api/request/*.kt (11 files)
  └── api/response/*.kt (6 files)

Phase 3: APIGateways (Kotlin共通化)
  ├── gateway/AuthGateway.kt
  ├── gateway/AlbumGateway.kt
  ├── gateway/MemoryGateway.kt
  └── gateway/UserGateway.kt

Phase 4: Repositories
  ├── Adapters (interface定義)
  │   ├── adapter/SecureStorage.kt
  │   ├── adapter/FileStorage.kt
  │   └── adapter/NetworkMonitor.kt
  ├── Kotlin実装 Repository
  │   ├── repository/AuthSessionRepositoryImpl.kt
  │   ├── repository/ImageStorageRepositoryImpl.kt
  │   └── repository/ReachabilityRepositoryImpl.kt
  └── Bridge経由 Repository (interface only)
      ├── repository/AlbumRepository.kt
      ├── repository/MemoryRepository.kt
      ├── repository/UserRepository.kt
      └── repository/SyncQueueRepository.kt

Phase 5: UseCases (Kotlin共通化)
  ├── usecase/model/DeepLink.kt
  ├── usecase/model/SyncQueueItem.kt
  ├── usecase/mapper/AlbumMapper.kt
  ├── usecase/mapper/UserMapper.kt
  ├── usecase/mapper/MemoryMapper.kt
  ├── usecase/service/SyncQueueService.kt
  └── usecase/*.kt (9 UseCases)

Phase 6: iOS Adapters & Bridges
  ├── Adapters/KeychainSecureStorage.swift
  ├── Adapters/iOSFileStorage.swift
  ├── Adapters/NWPathMonitorAdapter.swift
  └── KMPBridge/*BridgeImpl.swift
```

---

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| SwiftData依存 | **Bridge経由** | DB層は複雑、そのまま維持 |
| Keychain/File/Network | **Adapter DI** | ロジック共通化、PF APIのみ注入 |
| HTTP Client | **Ktor共通化** | プラットフォーム依存なし |
| Flow-Swift連携 | **KMP-NativeCoroutines** | Combine互換性あり、成熟したライブラリ |
| 移行戦略 | **段階的** | 既存機能を壊さずレイヤーごとにKMP化 |

---

## Dependencies

**libs.versions.toml:**
```toml
[versions]
kotlinx-coroutines = "1.9.0"
kotlinx-datetime = "0.6.1"
kotlinx-serialization = "1.7.3"
ktor = "3.0.3"
kmp-nativecoroutines = "1.0.0-ALPHA-36"
ksp = "2.1.0-1.0.29"

[libraries]
kotlinx-coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "kotlinx-coroutines" }
kotlinx-datetime = { module = "org.jetbrains.kotlinx:kotlinx-datetime", version.ref = "kotlinx-datetime" }
kotlinx-serialization-json = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json", version.ref = "kotlinx-serialization" }
ktor-client-core = { module = "io.ktor:ktor-client-core", version.ref = "ktor" }
ktor-client-content-negotiation = { module = "io.ktor:ktor-client-content-negotiation", version.ref = "ktor" }
ktor-serialization-kotlinx-json = { module = "io.ktor:ktor-serialization-kotlinx-json", version.ref = "ktor" }
ktor-client-okhttp = { module = "io.ktor:ktor-client-okhttp", version.ref = "ktor" }
ktor-client-darwin = { module = "io.ktor:ktor-client-darwin", version.ref = "ktor" }

[plugins]
kotlinSerialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
nativeCoroutines = { id = "com.rickclephas.kmp.nativecoroutines", version.ref = "kmp-nativecoroutines" }
```

**shared/build.gradle.kts:**
```kotlin
plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidLibrary)
    alias(libs.plugins.kotlinSerialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.nativeCoroutines)
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.datetime)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.serialization.kotlinx.json)
        }
        androidMain.dependencies {
            implementation(libs.ktor.client.okhttp)
        }
        iosMain.dependencies {
            implementation(libs.ktor.client.darwin)
        }
    }
}
```

**iOS Swift Package:**
```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/rickclephas/KMP-NativeCoroutines",
        from: "1.0.0-ALPHA-36"
    )
]
```

---

## Verification Plan

1. **Build Verification**
   - `./gradlew :shared:build` - KMP module builds
   - `./gradlew :shared:embedAndSignAppleFrameworkForXcode` - iOS framework builds

2. **Unit Tests (commonTest)**
   - Domain model tests
   - API response parsing tests
   - Repository tests with mock adapters
   - UseCase tests with mock repositories

3. **iOS Integration**
   - Run iOS app with KMP framework
   - Verify Combine publishers work correctly
   - Verify all existing features work

4. **Manual Testing**
   - Deep link: `myapp://albums/{albumId}`
   - Offline mode: Create album offline → sync when online
   - Pagination: Scroll album/memory lists

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Swift-Kotlin interop | KMP-NativeCoroutines使用、primitive typesを優先 |
| Adapter complexity | 最小限のinterfaceに保つ |
| Bridge complexity | DTOを最小限に |
| KMP-NativeCoroutines version | バージョン固定、Kotlinアップデート後にテスト |
| Build time increase | Gradle build cache、incremental compilation |
