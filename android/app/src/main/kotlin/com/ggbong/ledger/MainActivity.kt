package com.ggbong.ledger

import android.app.ActivityManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        updateTaskTitle()
    }

    override fun onResume() {
        super.onResume()
        updateTaskTitle()
    }

    private fun updateTaskTitle() {
        setTaskDescription(
            ActivityManager.TaskDescription(getString(R.string.app_name))
        )
    }
}