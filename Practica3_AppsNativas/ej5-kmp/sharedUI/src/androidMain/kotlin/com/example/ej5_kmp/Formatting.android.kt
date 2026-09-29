package com.example.ej5_kmp

import java.text.DateFormat
import java.util.Date

actual fun formatDateTime(epochMillis: Long): String =
    DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT).format(Date(epochMillis))
