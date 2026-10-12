# BUNEO: Boyut Kapısı

Godot 4 ile geliştirilen, 2D platform oynanışından zorunlu 3D TPS/FPS alanlarına geçen Android odaklı bir oyun prototipi.
Android uygulaması yatay ekranda açılır. Ekran düğmeleri aynı anda hareket ve zıplama için çoklu dokunmayı destekler.

## Oynanış

- Altınları topla ve `ZIPLAMA +` düğmesiyle kalıcı yükseltme satın al.
- 2D bölümün sonundaki mor kapı oyuncuyu zorunlu olarak 3D bölgeye geçirir.
- 3D bölgede varsayılan kamera TPS'dir; `C` veya `KAMERA` düğmesi FPS/TPS arasında geçiş yapar.
- Kırmızı kapı 3D bölümü tamamlar ve yeni 2D koşusunu başlatır.

## Kontroller

| Eylem | Klavye | Android |
| --- | --- | --- |
| Hareket | WASD / ok tuşları | Ekran yön tuşları |
| Zıplama | Space | ZIPLA |
| TPS/FPS | C | KAMERA |
| Kamera bakışı | Fare | Ekranın sağ yarısında sürükleme |

## Çalıştırma

Godot 4.4 veya daha yeni sürümde `project.godot` dosyasını açıp F6/F5 ile çalıştırın.

Komut satırından hızlı doğrulama:

```bash
godot --path . --headless --editor --quit
```

Android dışa aktarma ayarı `export_presets.cfg` içindedir. APK üretmek için Godot Android export template ve Android SDK kurulumu gerekir.

## Görsel varlıklar

2D arka plan, platform, altın ve karakter görselleri [Kenney Platformer Art Deluxe](https://kenney.nl/assets/platformer-art-deluxe) paketinden alınmıştır. Lisans: [CC0 1.0](assets/kenney/LICENSE.txt).
