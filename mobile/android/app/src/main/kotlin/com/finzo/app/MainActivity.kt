package com.finzo.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import java.util.ArrayList

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.finzo.app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getRecentSms") {
                val seconds = call.argument<Int>("seconds") ?: 20
                // Run in background thread if heavy? SMS query is fast enough usually, 
                // but let's just do it directly for simplicity as per rules.
                try {
                    val msgs = getRecentSms(seconds)
                    result.success(msgs)
                } catch (e: Exception) {
                    result.error("SMS_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getRecentSms(seconds: Int): List<Map<String, String>> {
        val messages = ArrayList<Map<String, String>>()
        
        try {
            android.util.Log.d("SMS_DEBUG", "Starting SMS scan for last $seconds seconds")
            
            val currentTime = System.currentTimeMillis()
            val timeWindow = currentTime - (seconds.toLong() * 1000L)
            android.util.Log.d("SMS_DEBUG", "Time window: $timeWindow to $currentTime")

            // Try to read from all SMS (inbox + sent)
            val uri = Uri.parse("content://sms/")
            android.util.Log.d("SMS_DEBUG", "Using URI: $uri")
            
            // "date" in SMS provider is ms since epoch
            val selection = "date >= ?"
            val selectionArgs = arrayOf(timeWindow.toString())
            val sortOrder = "date DESC LIMIT 100"

            android.util.Log.d("SMS_DEBUG", "Querying SMS content provider...")
            val cursor = contentResolver.query(
                uri,
                arrayOf("address", "body", "date", "_id", "type"),
                selection,
                selectionArgs,
                sortOrder
            )

            if (cursor == null) {
                android.util.Log.e("SMS_ERROR", "Cursor is null - permission may be denied or SMS provider unavailable")
                return messages
            }

            android.util.Log.d("SMS_DEBUG", "Cursor count: ${cursor.count}")

            cursor.use {
                if (it.moveToFirst()) {
                    val idxAddress = it.getColumnIndex("address")
                    val idxBody = it.getColumnIndex("body")
                    val idxDate = it.getColumnIndex("date")
                    val idxId = it.getColumnIndex("_id")

                    android.util.Log.d("SMS_DEBUG", "Column indices - address:$idxAddress, body:$idxBody, date:$idxDate, id:$idxId")

                    do {
                        val address = if (idxAddress >= 0) it.getString(idxAddress) ?: "" else ""
                        val body = if (idxBody >= 0) it.getString(idxBody) ?: "" else ""
                        val date = if (idxDate >= 0) it.getString(idxDate) ?: "" else ""
                        val id = if (idxId >= 0) it.getString(idxId) ?: "" else ""
                        
                        val map = HashMap<String, String>()
                        map["address"] = address
                        map["body"] = body
                        map["date"] = date
                        map["id"] = id
                        messages.add(map)
                        
                        // Log first message for debugging
                        if (messages.size == 1) {
                            android.util.Log.d("SMS_DEBUG", "First SMS - From: $address, Date: $date")
                        }
                    } while (it.moveToNext())
                } else {
                    android.util.Log.d("SMS_DEBUG", "Cursor is empty - no SMS found in time window")
                }
            }
        } catch (e: SecurityException) {
            android.util.Log.e("SMS_ERROR", "SecurityException - SMS permission not granted: ${e.message}")
        } catch (e: Exception) {
            android.util.Log.e("SMS_ERROR", "Error reading SMS: ${e.message}")
            e.printStackTrace()
        }
        
        android.util.Log.d("SMS_DEBUG", "Found ${messages.size} SMS messages")
        return messages
    }
}
