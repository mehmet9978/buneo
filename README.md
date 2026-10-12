# BUNEO: Boyut Kapısı

Godot 4 ile geliştirilen Android odaklı, tek bir 3D dünya içinde 2D bakış ve TPS/FPS kamera geçişi yapan platform oyunu.
Android uygulaması yatay ekranda açılır. Ekran düğmeleri aynı anda hareket ve zıplama için çoklu dokunmayı destekler.

0.4 sürümünde canlı dünya arka planlı ana menü, kart tabanlı mobil HUD, yeni sonuç/duraklatma ekranları ve doğal koşu-zıplama animasyonlarına sahip yeni maskot karakter eklendi.

## Oynanış

- Yaklaşık 315 oyun birimi uzunluğundaki parkurda altınları topla ve `ZIPLAMA +` ile kalıcı yükseltme satın al.
- Parkurun tamamı aynı 3D sahnede ve aynı animasyonlu karakterle oynanır. İlk kısımda kamera karşıdan bakar, hareket 2D düzleme kilitlidir.
- Mor kapıda kamera kesintisiz olarak karakterin arkasına döner ve derinlik yönünde hareket açılır. Dünya ve oyuncu yeniden oluşturulmaz.
- 3D görünümde `C` veya `KAMERA` düğmesi FPS/TPS arasında geçiş yapar. Turuncu kapıda kamera yeniden karşıdan bakar.
- Parkurda üç farklı zemin tonu, atlanabilir dönen engeller, yükseltilmiş platformlar, kontrol bayrakları ve can sistemi bulunur. Düşman yoktur.
- Canlı çevrede sürüklenen bulutlar, atmosferik gökyüzü, rüzgârla sallanan çimenler, meyveli ağaçlar, çalılar, kayalar, çitler, sandıklar ve uzak kuleler bulunur.
- Uçuruma düşüldüğünde veya canlar bitince son kontrol noktasından devam edilir. Bitiş kapısı 15 altın verir ve süre/altın özetini gösterir.
- Duraklatma ve yeniden oynama ekranları ile altın, zıplama, hasar, kontrol noktası ve kamera geçişi sesleri bulunur.

## Kontroller

| Eylem | Klavye | Android |
| --- | --- | --- |
| Hareket | 2D: A/D; 3D: W/S ileri-geri, A/D yan hareket | Ekran yön tuşları |
| Zıplama | Space | ZIPLA |
| TPS/FPS | C | KAMERA |
| Kamera bakışı | Fare | Ekranın sağ yarısında sürükleme |
| Duraklat | Esc | Üst çubuktaki `II` |

## Çalıştırma

Godot 4.4 veya daha yeni sürümde `project.godot` dosyasını açıp F6/F5 ile çalıştırın.

Komut satırından hızlı doğrulama:

```bash
godot --path . --headless --editor --quit
```

Android dışa aktarma ayarı `export_presets.cfg` içindedir. APK üretmek için Godot Android export template ve Android SDK kurulumu gerekir.

## Görsel varlıklar

Karakter ve yeni çevre modelleri [Quaternius Ultimate Platformer Pack](https://quaternius.com/packs/ultimateplatformer.html) paketinden alınmıştır ve [CC0 1.0](assets/quaternius_platformer/License.txt) kapsamındadır. Sesler [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) paketindendir. Arayüzde Google Fonts üzerinden Bungee ve Nunito Sans kullanılır; lisansları `assets/fonts` klasöründedir. Önceki Kenney kaynakları da depoda kendi CC0 lisanslarıyla korunur.
