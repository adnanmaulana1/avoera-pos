package id.avoera.avoera_pos

import android.content.ActivityNotFoundException
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
/// lalu Dart menawarkan tombol Pasang lagi), atau error dengan
/// kode bertahap supaya penyebab asli TERLIHAT di dialog
/// (v0.10.15): 'IZIN' (kedua intent halaman izin gagal),
/// 'PROVIDER' (FileProvider menolak jalur berkas), 'BUKA'
/// (intent pemasang gagal dibuka — pesan membawa nama
/// pengecualiannya).
///
/// Riwayat: v0.10.12 menambah pemeriksaan izin
/// canRequestPackageInstalls (tanpanya startActivity melempar
/// di Xiaomi Adnan). Uji v0.10.13/v0.10.14 di HP yang sama
/// TETAP gagal di langkah yang belum diketahui — pesan
/// pengecualian versi lama ditelan Dart ('gagal' polos), jadi
/// v0.10.15 membuka alasannya + menambah jalur cadangan
/// ACTION_INSTALL_PACKAGE bila ACTION_VIEW tidak dikenal ROM.
class MainActivity : FlutterActivity() {
    private fun deskripsi(e: Exception): String =
        "${e.javaClass.simpleName}: ${e.message ?: "(tanpa pesan)"}"

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
                            result.error("IZIN", "${deskripsi(e)} | ${deskripsi(e2)}", null)
                        }
                    }
                    return@setMethodCallHandler
                }
                val uri = try {
                    FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.fileprovider",
                        File(path)
                    )
                } catch (e: Exception) {
                    result.error("PROVIDER", deskripsi(e), null)
                    return@setMethodCallHandler
                }
                try {
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addCategory(Intent.CATEGORY_DEFAULT)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success("dibuka")
                } catch (e: ActivityNotFoundException) {
                    // ROM tanpa penangan ACTION_VIEW untuk APK:
                    // coba intent khusus pemasangan.
                    try {
                        val intent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success("dibuka")
                    } catch (e2: Exception) {
                        result.error("BUKA", "${deskripsi(e)} | ${deskripsi(e2)}", null)
                    }
                } catch (e: Exception) {
                    result.error("BUKA", deskripsi(e), null)
                }
            }
    }
}
