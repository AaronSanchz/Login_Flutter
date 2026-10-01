// GUÍA DEL ARCHIVO: Anfitrión Android de Flutter. Registra fake_store/network para consultar conectividad validada antes del login. El catálogo y su gestión están en lib/*.dart.
// Consulta docs/GUIA_APRENDIZAJE_US01_US08.html para sintaxis, recorridos y ejercicios.

package com.example.fakestoreroles

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities

/** Aloja Flutter y expone la comprobación Android de red para US01. */
class MainActivity : FlutterActivity() {
    /** Registra el canal que ApiService.dart consulta antes del POST de acceso. */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fake_store/network")
            .setMethodCallHandler { call, result ->
                if (call.method != "hasInternetConnection") {
                    result.notImplemented()
                } else {
                    val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                    val network = manager.activeNetwork
                    val capabilities = network?.let { manager.getNetworkCapabilities(it) }
                    result.success(capabilities != null &&
                        capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                        capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED))
                }
            }
    }
}
