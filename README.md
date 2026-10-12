# BUNEO: Boyut Kapısı

Godot 4 ile geliştirilen Android odaklı, tek bir 3D dünya içinde 2D bakış ve TPS/FPS kamera geçişi yapan platform oyunu.
Android uygulaması yatay ekranda açılır. Ekran düğmeleri aynı anda hareket ve zıplama için çoklu dokunmayı destekler.

## Oynanış

- Yaklaşık 315 oyun birimi uzunluğundaki parkurda altınları topla ve `ZIPLAMA +` ile kalıcı yükseltme satın al.
- Parkurun tamamı aynı 3D sahnede ve aynı animasyonlu karakterle oynanır. İlk kısımda kamera karşıdan bakar, hareket 2D düzleme kilitlidir.
- Mor kapıda kamera kesintisiz olarak karakterin arkasına döner ve derinlik yönünde hareket açılır. Dünya ve oyuncu yeniden oluşturulmaz.
- 3D görünümde `C` veya `KAMERA` düğmesi FPS/TPS arasında geçiş yapar. Turuncu kapıda kamera yeniden karşıdan bakar.
- Canlı çevrede sürüklenen bulutlar, rüzgârla sallanan çimen ve çiçekler, ağaçlar, kayalar ve mantarlar bulunur. Düşman yoktur.
- Bitiş kapısı 15 altın ödül verir. Uçuruma düşüldüğünde son kontrol noktasından devam edilir.

## Kontroller

| Eylem | Klavye | Android |
| --- | --- | --- |
| Hareket | A/D (2D ve 3D), W/S (3D derinlik) | Ekran yön tuşları |
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

Animasyonlu karakter [Kenney Animated Characters Protagonists](https://kenney.nl/assets/animated-characters-protagonists), ağaç/çimen/çiçek/kaya modelleri [Kenney Nature Kit](https://kenney.nl/assets/nature-kit) paketlerinden alındı. Kaynak varlıklar [CC0 1.0](assets/kenney_3d/LICENSE.txt) lisanslıdır.
