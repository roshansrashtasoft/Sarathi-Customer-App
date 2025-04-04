package com.example.sarathi_customer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.view.WindowManager.LayoutParams

import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.SurfaceView

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        window.addFlags(LayoutParams.FLAG_SECURE)
        super.configureFlutterEngine(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        if (!setSecureSurfaceView()) {
//            Log.e("MainActivity", "Could not secure the MainActivity!")
//            // React as appropriate.
//        }
    }

    private fun setSecureSurfaceView(): Boolean {
        val content = findViewById<ViewGroup>(android.R.id.content)
        if (!isNonEmptyContainer(content)) {
            return false
        }
        val splashView = content.getChildAt(0)
        if (!isNonEmptyContainer(splashView)) {
            return false
        }
        val flutterView = (splashView as ViewGroup).getChildAt(0)
        if (!isNonEmptyContainer(flutterView)) {
            return false
        }
        val surfaceView = (flutterView as ViewGroup).getChildAt(0)
        if (surfaceView !is SurfaceView) {
            return false
        }
        surfaceView.setSecure(true)
        this.window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        return true
        return false
    }

    private fun isNonEmptyContainer(view: View): Boolean {
        if (view !is ViewGroup) {
            return false
        }
        if (view.childCount < 1) {
            return false
        }
        return true
    }
}
