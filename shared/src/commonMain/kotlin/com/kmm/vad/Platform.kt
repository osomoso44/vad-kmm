package com.kmm.vad

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform