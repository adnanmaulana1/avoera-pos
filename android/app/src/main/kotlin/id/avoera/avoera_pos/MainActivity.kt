package id.avoera.avoera_pos

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Kanal 'avoera/installer' untuk pembaruan dari dalam
/// aplikasi: Dart meminta pemasang Android dibuka untuk berkas
/// APK yang sudah diunduh ke cache. Android sendiri yang
/// menampilkan jendela "Pasang" — pengguna tetap menekan
/// tombolnya (aturan Android, tidak bisa dilewati).
///
/// Hasil untuk Dart: 'dibuka' (pemasang tampil), 'perlu-izin'
/// (halaman izin sudah dibuka — pengguna mengaktifkan sekali,
/// lalu Dart menawarkan tombol Pasang lagi), atau error.
///
/// PERBAIKAN v0.10.12: sejak Android 8, memasang APK dari luar
/// Play Store butuh izin per-aplikasi "pasang aplikasi tidak
/// dikenal" (canRequestPackageInstalls). Versi lama langsung
/// startActivity tanpa memeriksa izin ini → di HP Xiaomi
/// Adnan startActivity melempar pengecualian, unduhan 61 MB
/// sukses tapi pemasang gagal dibuka (ketahuan dari uji
/// langsung Adnan 2026-11-16 00:43 WITA). Kini izin diperiksa
/// dulu dan pengguna diarahkan ke halaman izinya.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avoera/installer")
            .setMethodCallHandler { call, result ->
                if (call.method != "install") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrEmpty()) {
                    result.error("ARG", "path kosong", null)
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                    !packageManager.canRequestPackageInstalls()
                ) {
                    try {
                        startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success("perlu-izin")
                    } catch (e: Exception) {
                        // Sebagian ROM tidak mengenal intent
                        // spesifik per-paket — coba bentuk
                        // umumnya (daftar sumber tidak dikenal).
                        try {
                            startActivity(
                                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                            result.success("perlu-izin")
                        } catch (e2: Exception) {
                            result.error("GAGAL", e2.message, null)
                        }
                    }
                    return@setMethodCallHandler
                }
                try {
                    val uri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.fileprovider",
                        File(path)
                    )
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success("dibuka")
                } catch (e: Exception) {
                    result.error("GAGAL", e.message, null)
                }
            }
    }
}
