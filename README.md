# Memories - Photo Album App

A mobile application where users can log in, manage their profile, and create albums of photo memories. Built with an offline-first architecture and Kotlin Multiplatform (KMP) for shared business logic.

## Platforms

- **iOS**: Swift + SwiftUI
- **Android**: Kotlin + Compose

---

## Setup

### Install

- [Xcode](https://developer.apple.com/xcode/) (iOS development)
- [Android Studio](https://developer.android.com/studio) (Android development + KMP)

### Build

1. Open `frontend` directory in Android Studio
2. Wait for Gradle sync to complete (or run **File > Sync Project with Gradle Files**)

### iOS

```bash
cd frontend

# Build the KMP shared framework
./gradlew :shared:assembleXCFramework

# Open Xcode project
open iosApp/iosApp.xcodeproj
```

### Android

Build and run on emulator or device via Android Studio.

---

## Architecture Overview

### Clean Architecture + MVVM

The app follows **Clean Architecture** with clear separation of concerns:

```mermaid
graph BT
    subgraph Data - KMP Shared
        E[Repositories]
        F[Gateways]
        G[ApiClient]
    end

    subgraph Domain - KMP Shared
        C[UseCases]
        D[Domains]
    end

    subgraph Presentation
        A1[SwiftUI iOS] --> B1[ViewModel]
        A2[Compose Android] --> B2[ViewModel]
    end

    F --> G
    C --> E
    C --> F
    C --> D
    B1 --> C
    B2 --> C
```

### Module Structure

**KMP Shared (shared)**

| Package | Responsibility |
|---------|----------------|
| **api** | API client, requests, responses |
| **domain** | Domain models |
| **gateway** | API abstractions |
| **mapper** | DTO ↔ Domain mappers |
| **repository** | Data layer protocols |
| **usecase** | Screen-level application logic, orchestrates Repository/Gateway |

**iOS (iosApp)**

| Module | Responsibility |
|--------|----------------|
| **Domains** | Extensions for KMP domain models (Swift type conversions, Identifiable) |
| **Utilities** | Keychain, formatters |
| **Repositories** | SwiftData + KMP bridge implementations |
| **UseCases** | Swift adapters wrapping KMP use cases |
| **UILogics** | ViewModels, Router protocol |
| **UIComponents** | SwiftUI views |
| **Memories** | DI container, app configuration |

**Android (composeApp)**

| Package | Responsibility |
|---------|----------------|
| **data/repository** | In-memory cache (Token/UserId only persisted) |
| **di** | DI containers (AppContainer, AuthenticatedContainer) |
| **ui/uilogics** | ViewModels |
| **ui/uicomponents** | Compose screens |
| **ui/navigation** | Navigation graph, Routes |


---

## Image Caching Approach

### Display Caching

Images are automatically cached when displayed.

| Platform | Library | Cache |
|----------|---------|-------|
| **iOS** | SDWebImage | Memory + Disk |
| **Android** | Coil | Memory + Disk |

### Offline Image Storage

User-selected images (avatar, album cover, memory photo) are saved to the device's file system. Only the file path is stored in the data model.

```
User selects image
        │
        ▼
Save to FileSystem
        │
        ▼
Store path in model (imageLocalPath)
        │
        ▼
On sync: Upload to server → Delete local file
```

---

## Offline Sync Strategy

All write operations work offline and sync when connectivity is restored.

| Platform | Local Storage |
|----------|---------------|
| **iOS** | SwiftData (persistent) |
| **Android** | In-memory cache |

```mermaid
flowchart TD
    A[Create Album / Add Memory / Update Profile] --> B[Save Locally + SyncStatus = PENDING]
    B --> C[Enqueue to Pending Queue]
    C --> D[UI Updated Immediately]
    D --> E{Online?}
    E -->|Yes| F[Process Queue]
    E -->|No| G[Wait for Connectivity]
    G -->|Connected| F
    F --> H[Sync to Server]
    H --> I[SyncStatus = SYNCED]
```

### Support Sync Queue Operations

| Entity | Create | Update |
|--------|--------|--------|
| **Album** | ✅ | ✅ |
| **Memory** | ✅ | - |
| **User Profile** | - | ✅ |

### Debug Mode

To test offline sync behavior, enable debug mode by setting `onlineState` to `.debug` in the app configuration. This injects `DebugReachabilityRepository` instead of the production implementation, allowing manual control of connectivity state.

| Offline Sync Demo |
|-------------------|
| <img src="resource/gifs/Simulator Screen Recording - iPhone 16 - 2026-02-03 at 00.08.08.gif" width="200"/> |

**iOS** (`AppConfig.swift`)

```swift
public static let onlineState: OnlineState = .debug(initialState: false)

public static let reachabilityRepository: ReachabilityRepositoryProtocol = {
    switch onlineState {
    case .debug(let initialState):
        return DebugReachabilityRepository(isOnline: initialState)
    case .production:
        return ReachabilityRepository()
    }
}()
```

**Android** (`AppContainer.kt`)

```kotlin
val onlineState: OnlineState = OnlineState.Debug(initialState = false)
```

When debug mode is enabled, the Album List screen displays:

- **Queues Button**: Tap to view the list of pending sync operations
- **Connectivity Toggle Button**: Tap to switch between online/offline states

This allows you to verify that sync operations are triggered when transitioning from offline to online.

---

## Deep Linking

### Supported URL Scheme

```
myapp://albums/{albumId}
```

| Cold Start | Warm Start | Unauthenticated |
|------------|------------|-----------------|
| <img src="resource/gifs/coldstart.gif" width="200"/> | <img src="resource/gifs/warmstart.gif" width="200"/> | <img src="resource/gifs/unauth.gif" width="200"/> |

### Testing Deep Links

**iOS**

```bash
xcrun simctl openurl booted "myapp://albums/1"
```

You can also test by entering the URL directly in Safari on the simulator.

**Android**

```bash
adb shell am start -a android.intent.action.VIEW -d "myapp://albums/1"
```

---

## Automated Tests

### Running Tests

**Shared (Domain / UseCase / Gateway / Mapper)**

Upper layers from UseCase are shared across platforms. Run cross-platform tests with:

```bash
cd frontend
./gradlew :shared:allTests
```

**Platform-specific (UILogic / ViewModel)**

```bash
# Android (Compose)
./gradlew :composeApp:testDebugUnitTest

# iOS (requires simulator)
xcodebuild test -scheme UILogics -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0'
```

### Test Coverage

| Layer | Tests | Framework |
|-------|-------|-----------|
| **Domain Models** | ✅ | Kotlin Test |
| **Mappers** | ✅ | Kotlin Test |
| **Gateways** | ✅ | Kotlin Test (MockApiClient) |
| **Use Cases** | ✅ | Kotlin Test (Mock repositories) |
| **ViewModels (iOS)** | ✅ | Swift Testing |
| **ViewModels (Android)** | ✅ | JUnit |

---

## Tradeoffs and Future Improvements

### Current Tradeoffs

| Decision | Tradeoff | Rationale |
|----------|----------|-----------|
| **Clean Architecture** | Boilerplate increase | Clear separation of concerns |
| **KMP for business logic** | Learning curve, build complexity | Code sharing, native UI per platform |
| **Optimistic updates** | Potential UI inconsistency | Better perceived performance |

### Future Improvements

1. **Conflict Resolution**
   - Handle server-side changes during offline period
   - Implement last-write-wins or merge strategies

2. **Background Sync**
   - Use iOS Background Tasks for periodic sync
   - Sync when app enters background

3. **E2E Tests**
   - Add UI tests for critical flows (login, deep link)
   - Implement screenshot testing

---

