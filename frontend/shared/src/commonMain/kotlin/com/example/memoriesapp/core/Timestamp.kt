package com.example.memoriesapp.core

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime

/**
 * A wrapper around Instant for timestamp handling.
 */
data class Timestamp(val value: Instant) : Comparable<Timestamp> {

    val epochMillis: Long get() = value.toEpochMilliseconds()

    override fun compareTo(other: Timestamp): Int = value.compareTo(other.value)

    override fun toString(): String = value.toString()

    fun toLocalDate(timeZone: TimeZone = TimeZone.currentSystemDefault()): LocalDate {
        return value.toLocalDateTime(timeZone).date
    }

    companion object {
        fun now(): Timestamp = Timestamp(Clock.System.now())

        fun fromEpochMillis(millis: Long): Timestamp = Timestamp(Instant.fromEpochMilliseconds(millis))

        fun parse(isoString: String): Timestamp = Timestamp(Instant.parse(isoString))
    }
}
