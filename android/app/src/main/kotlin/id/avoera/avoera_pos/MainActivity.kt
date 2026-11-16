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
///
/// v0.10.19: uji v0.10.18 di HP Adnan membuktikan folder
/// code_cache TETAP ditolak FileProvider (pesan PROVIDER yang
/// sama) walau <code-cache-path> sudah terdaftar sejak
/// v0.10.17 — terverifikasi ada di dalam APK terbit; penolakan
/// itu khas ROM (dugaan beda bentuk alamat folder). Maka dua
/// lapis obat: (1) Dart kini mengunduh ke folder CACHE biasa
/// (path_provider), bukan Directory.systemTemp; (2) di sini,
/// bila getUriForFile tetap menolak jalur berkas, berkas
/// DISALIN ke cacheDir (akar <cache-path>) lalu dicoba lagi
/// dari sana sebelum menyerah dengan error PROVIDER.
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
                val otoritas = "${applicationContext.packageName}.fileprovider"
                val uri = try {
                    FileProvider.getUriForFile(this, otoritas, File(path))
                } catch (e: Exception) {
                    // Cadangan v0.10.19: jalur berkas di luar
                    // akar yang dikenal FileProvider — salin ke
                    // cacheDir (akar <cache-path>, selalu
                    // terdaftar) lalu coba lagi dari sana.
                    try {
                        val asal = File(path)
                        val salinan = File(cacheDir, asal.name)
                        asal.copyTo(salinan, overwrite = true)
                        FileProvider.getUriForFile(this, otoritas, salinan)
                    } catch (e2: Exception) {
                        result.error("PROVIDER", "${deskripsi(e)} | salin-gagal: ${deskripsi(e2)}", null)
                        return@setMethodCallHandler
                    }
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
