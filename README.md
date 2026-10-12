# BUNEO: Boyut Kapısı

Godot 4 ile geliştirilen Android odaklı, aynı 3D dünyada tam düz 2D görünüm ile FPS arasında geçiş yapan platform oyunu.
Android uygulaması yatay ekranda açılır. Ekran düğmeleri aynı anda hareket ve zıplama için çoklu dokunmayı destekler.

0.6 sürümünde 2D kamera eğimsiz ortografik görünüm kullanır: blokların üst/yan yüzleri perspektifle açığa çıkmaz. 3D'ye geçiş doğrudan karakterin gözündeki FPS'ye ulaşır; TPS modu ve kamera seçimi kaldırıldı. Bu sürüm tek bölümlü bir Android alpha sürümüdür.

## Oynanış

- Yaklaşık 315 oyun birimi uzunluğundaki parkurda altınları topla ve özellikler ekranından kalıcı yükseltme satın al.
- Parkurun tamamı aynı 3D sahnede ve aynı animasyonlu karakterle oynanır. İlk kısımda kamera karşıdan bakar, hareket 2D düzleme kilitlidir.
- Mor kapıda kamera aynı karakterin göz hizasına yaklaşır ve FPS hareketi açılır. Dünya ve oyuncu yeniden oluşturulmaz.
- Mor kapı boyut gücünü açar. `BOYUT` / `Q` ile bulunduğun konumu koruyarak 2D ve 3D arasında geçebilirsin. 2D'de o anki derinlik düzleminde hareket edersin.
- Duvarın arkasındaki düğmeye FPS'de yanından dolaşarak ulaş. Mavi 2D ve mor 3D basamakları arasında havada boyut değiştirerek perspektif köprüsünü geç. FPS'de hedeflere 1→2→3 sırasıyla nişan alıp etkileşerek enerji kilidini aç.
- Hareketli, basınca çöken, zamanla kaybolan ve moda göre aktifleşen platformlar; periyodik lazerler, yana hareket eden testereler ve yüksek rotaya fırlatan bir zıplama pedi bulunur.
- Etkileşimle kırılan sandıklar 3 altın verir. Yan mağara, yüksek bulut yolu ve enerji kilidi arkasındaki hazine alanının her biri 5 altınlık bir kristal içerir.
- FPS'de hareket baktığın yönü takip eder. Turuncu kapıda kamera yeniden tam düz 2D bakışa döner.
- Parkurda üç farklı zemin tonu, atlanabilir dönen engeller, yükseltilmiş platformlar, kontrol bayrakları ve can sistemi bulunur. Düşman yoktur.
- Canlı çevrede sürüklenen bulutlar, atmosferik gökyüzü, rüzgârla sallanan çimenler, meyveli ağaçlar, çalılar, kayalar, çitler, sandıklar ve uzak kuleler bulunur.
- Uçuruma düşüldüğünde veya canlar bitince son kontrol noktasından devam edilir. Bitiş kapısı 15 altın verir ve süre/altın özetini gösterir.
- Üç ana bulmaca çözülmeden bitiş ödülü alınamaz. Bitiş 1 yıldız, 3 dakikanın altında en fazla 3 düşüşle bitiş 1 ek yıldız, aynı turda üç kristal 1 ek yıldız verir. Yeniden doğma ve düşüşler aynı sayaçta sayılır.
- Zıplama en fazla 3 seviyedir. Altın mıknatısı (2 seviye), her turda bir tuzak hasarını engelleyen kalkan (1 seviye) ve hava kontrolü (1 seviye) satın alınabilir. Kalkan uçuruma düşmeyi engellemez.
- Altın, yükseltmeler, bulunan kristaller, en iyi süre/yıldız ve ayarlar yerel dosyada korunur. Yazma önce geçici dosyada tamamlanır; ana kayıt okunamıyorsa yedek denenir. Eski kayıtlar zıplama sınırına taşınır.
- Ses, kamera hassasiyeti, dokunmatik boyut/saydamlık, titreşim ve üç grafik düzeyi ayarlanabilir. Android uygulaması arka plana geçince duraklar.
- Duraklatma ve yeniden oynama ekranları ile altın, zıplama, hasar, kontrol noktası ve kamera geçişi sesleri bulunur.

## Kontroller

| Eylem | Klavye | Android |
| --- | --- | --- |
| Hareket | 2D: A/D; 3D: W/S ileri-geri, A/D yan hareket | Ekran yön tuşları |
| Zıplama | Space | ZIPLA |
| 2D/3D boyut değişimi | Q | BOYUT |
| Sandık, düğme, FPS hedefi | E | ETKİLEŞ |
| Kamera bakışı | Fare | Ekranın sağ tarafında düğmelerin dışındaki alanda sürükleme |
| Duraklat | Esc | Üst çubuktaki `II` |

## Çalıştırma

Godot 4.4 veya daha yeni sürümde `project.godot` dosyasını açıp F6/F5 ile çalıştırın.

Komut satırından hızlı doğrulama:

```bash
godot --path . --headless --import
godot --path . --headless -s res://tests/smoke_test.gd
godot --path . --headless -s res://tests/course_test.gd
godot --path . --headless -s res://tests/touch_test.gd
godot --path . --headless -s res://tests/save_test.gd
godot --path . --headless -s res://tests/camera_test.gd
```

Testler ayrı kayıt dosyaları kullanır, oyuncunun kayıtlarını değiştirmez. Parkur testi gerçek hareket girdileriyle köprü, düğme ve gizli rotaların erişilebilirliğini doğrular. Bölge başlangıçlarına test amaçlı konumlandırma yapılır; bu test tam bir baştan sona kullanıcı cihaz testi değildir.

Android dışa aktarma ayarı `export_presets.cfg` içindedir. APK üretmek için Godot Android export template ve Android SDK kurulumu gerekir.

Paylaşılan APK debug anahtarıyla imzalı test paketidir. Fiziksel Android cihazlarda performans ve güvenli ekran alanı kontrolü, mağaza için kalıcı release anahtarı/AAB ve ikinci temalı bölüm [geliştirme planında](docs/development-plan.md) sonraki aşamadadır.

## Görsel varlıklar

Karakter ve yeni çevre modelleri [Quaternius Ultimate Platformer Pack](https://quaternius.com/packs/ultimateplatformer.html) paketinden alınmıştır ve [CC0 1.0](assets/quaternius_platformer/License.txt) kapsamındadır. Sesler [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) paketindendir. Arayüzde Google Fonts üzerinden Bungee ve Nunito Sans kullanılır; lisansları `assets/fonts` klasöründedir. Önceki Kenney kaynakları da depoda kendi CC0 lisanslarıyla korunur.
