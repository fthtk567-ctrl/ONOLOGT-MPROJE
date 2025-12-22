import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Kurye Uygulaması - Bildirim ve Ses Yönetim Servisi
/// 
/// Bu servis kurye uygulamasında çeşitli olaylar için sesli ve görsel bildirimler sağlar:
/// - Yeni sipariş atandı
/// - Teslimat yaklaşıyor (müşteriye yaklaşma bildirimi)
/// - Teslimat tamamlandı
/// - Acil sipariş bildirimi
/// - Toplama noktasına varış
/// 
/// Web platformunda HTML5 Audio API kullanılır.
/// Mobil platformlarda henüz ses desteği eklenmemiştir.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();

  // Ses dosyaları (browser'da data URL olarak gömülü)
  // Not: Gerçek projede bu dosyalar assets klasöründen yüklenebilir
  
  // Yeni sipariş atandığında çalınacak ses (neşeli bildirim)
  final String _newOrderAssignedSoundUrl = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACAg4aDiIOIg4iDiIOIg4iDiIOIg4iDiIOIg4iDiIOIg4iDiIOHg4eDh4OHg4eDh4OHg4eDh4OHg4eDh4OGg4aDhoOGg4aDhoOGg4aDhoOGg4aDhoOFg4WDhYOFg4WDhYOFg4WDhYOFg4WDhIOEg4SDhIOEg4SDhIOEg4SDhIOEg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4KDgoOCg4KDgoOCg4KDgoOCg4KDgoOBg4GDgYOBg4GDgYOBg4GDgYOBg4GDgIOAg4CDgIOAg4CDgIOAg4CDgIOAg/+C/4L/gv+C/4L/gv+C/4L/gv+C/4L/gf+B/4H/gf+B/4H/gf+B/4H/gf+B/4D/gP+A/4D/gP+A/4D/gP+A/4D/gP9//3//f/9//3//f/9//3//f/9//3//fv9+/37/fv9+/37/fv9+/37/fv9+/33/ff99/33/ff99/33/ff99/33/ff98/3z/fP98/3z/fP98/3z/fP98/3z/e/97/3v/e/97/3v/e/97/3v/e/97/3r/ev96/3r/ev96/3r/ev96/3r/ev95/3n/ef95/3n/ef95/3n/ef95/3n/eP94/3j/eP94/3j/eP94/3j/eP94/3f/d/93/3f/d/93/3f/d/93/3f/dv92/3b/dv92/3b/dv92/3b/dv92/3X/df91/3X/df91/3X/df91/3X/dP90/3T/dP90/3T/dP90/3T/dP90/3P/c/9z/3P/c/9z/3P/c/9z/3P/cv9y/3L/cv9y/3L/cv9y/3L/cv9x/3H/cf9x/3H/cf9x/3H/cf9x/3D/cP9w/3D/cP9w/3D/cP9w/3D/b/9v/2//b/9v/2//b/9v/2//b/9u/27/bv9u/27/bv9u/27/bv9u/23/bf9t/23/bf9t/23/bf9t/23/bP9s/2z/bP9s/2z/bP9s/2z/bP9r/2v/a/9r/2v/a/9r/2v/a/9r/2r/av9q/2r/av9q/2r/av9q/2r/af9p/2n/af9p/2n/af9p/2n/af9o/2j/aP9o/2j/aP9o/2j/aP9o/2f/Z/9n/2f/Z/9n/2f/Z/9n/2f/Zv9m/2b/Zv9m/2b/Zv9m/2b/Zv9l/2X/Zf9l/2X/Zf9l/2X/Zf9l/2T/ZP9k/2T/ZP9k/2T/ZP9k/2T/Y/9j/2P/Y/9j/2P/Y/9j/2P/Y/9i/2L/Yv9i/2L/Yv9i/2L/Yv9i/2H/Yf9h/2H/Yf9h/2H/Yf9h/2H/YP9g/2D/YP9g/2D/YP9g/2D/YP9f/1//X/9f/1//X/9f/1//X/9f/17/Xv9e/17/Xv9e/17/Xv9e/17/Xf9d/13/Xf9d/13/Xf9d/13/Xf9c/1z/XP9c/1z/XP9c/1z/XP9c/1v/W/9b/1v/W/9b/1v/W/9b/1v/Wv9a/1r/Wv9a/1r/Wv9a/1r/Wv9Z/1n/Wf9Z/1n/Wf9Z/1n/Wf9Z/1j/WP9Y/1j/WP9Y/1j/WP9Y/1j/V/9X/1f/V/9X/1f/V/9X/1f/V/9W/1b/Vv9W/1b/Vv9W/1b/Vv9W/1X/Vf9V/1X/Vf9V/1X/Vf9V/1X/VP9U/1T/VP9U/1T/VP9U/1T/VP9T/1P/U/9T/1P/U/9T/1P/U/9T/1L/Uv9S/1L/Uv9S/1L/Uv9S/1L/Uf9R/1H/Uf9R/1H/Uf9R/1H/Uf9Q/1D/UP9Q/1D/UP9Q/1D/UP9Q/0//T/9P/0//T/9P/0//T/9P/0//Tv9O/07/Tv9O/07/Tv9O/07/Tv9N/03/Tf9N/03/Tf9N/03/Tf9N/0z/TP9M/0z/TP9M/0z/TP9M/0z/S/9L/0v/S/9L/0v/S/9L/0v/S/9K/0r/Sv9K/0r/Sv9K/0r/Sv9K/0n/Sf9J/0n/Sf9J/0n/Sf9J/0n/SP9I/0j/SP9I/0j/SP9I/0j/SP9H/0f/R/9H/0f/R/9H/0f/R/9H/0b/Rv9G/0b/Rv9G/0b/Rv9G/0b/Rf9F/0X/Rf9F/0X/Rf9F/0X/Rf9E/0T/RP9E/0T/RP9E/0T/RP9E/0P/Q/9D/0P/Q/9D/0P/Q/9D/0P/Qv9C/0L/Qv9C/0L/Qv9C/0L/Qv9B/0H/Qf9B/0H/Qf9B/0H/Qf9B/0D/QP9A/0D/QP9A/0D/QP9A/0D/P/8//z//P/8//z//P/8//z//P/4+/j7+Pv4+/j7+Pv4+/j7+Pv49/j3+Pf49/j3+Pf49/j3+Pf49/jz+PP48/jz+PP48/jz+PP48/jz+PL48vjy+PL48vjy+PL48vjy+PL48fjx+PH48fjx+PH48fjx+PH48fjw+PD48Pjw+PD48Pjw+PD48Pjw+O/47/jv+O/47/jv+O/47/jv+O/46/jr+Ov46/jr+Ov46/jr+Ov46/jn+Of45/jn+Of45/jn+Of45/jn+Ob45vjm+Ob45vjm+Ob45vjm+Ob45fjl+OX45fjl+OX45fjl+OX45fjk+OT45Pjk+OT45Pjk+OT45Pjk+OP44/jj+OP44/jj+OP44/jj+OP44vji+OL44vji+OL44vji+OL44vji+OH44fjh+OH44fjh+OH44fjh+OH44Pjg+OD44Pjg+OD44Pjg+OD44Pjf+N/43/jf+N/43/jf+N/43/jf+N743vjc=';
  
  // Teslimat yaklaşıyor sesi (uyarı tonu)
  final String _deliveryApproachingSoundUrl = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACAhYiFiIWIhYiFiIWIhYiFiIWIhYiFiIWIhYiFiIWIhYiFiIWHhYeHh4eHh4eHh4eHh4eHh4eHh4eHh4aHhoeGh4aHhoeGh4aHhoeGh4aHhoeGh4WHhYeFh4WHhYeFh4WHhYeFh4WHhYeFh4SHhIeEh4SHhIeEh4SHhIeEh4SHhIeEh4OHg4eDh4OHg4eDh4OHg4eDh4OHg4eDh4KHgoeCh4KHgoeCh4KHgoeCh4KHgoeCh4GHgYeBh4GHgYeBh4GHgYeBh4GHgYeBh4CHgIeAh4CHgIeAh4CHgIeAh4CHgIeAh/+G/4b/hv+G/4b/hv+G/4b/hv+G/4b/hf+F/4X/hf+F/4X/hf+F/4X/hf+F/4T/hP+E/4T/hP+E/4T/hP+E/4T/hP+D/4P/g/+D/4P/g/+D/4P/g/+D/4L/gv+C/4L/gv+C/4L/gv+C/4L/gv+B/4H/gf+B/4H/gf+B/4H/gf+B/4D/gP+A/4D/gP+A/4D/gP+A/4D/f/9//3//f/9//3//f/9//3//f/9+/37/fv9+/37/fv9+/37/fv9+/33/ff99/33/ff99/33/ff99/33/fP98/3z/fP98/3z/fP98/3z/fP98/3v/e/97/3v/e/97/3v/e/97/3v/ev96/3r/ev96/3r/ev96/3r/ev96/3n/ef95/3n/ef95/3n/ef95/3n/eP94/3j/eP94/3j/eP94/3j/eP94/3f/d/93/3f/d/93/3f/d/93/3f/dv92/3b/dv92/3b/dv92/3b/dv92/3X/df91/3X/df91/3X/df91/3X/dP90/3T/dP90/3T/dP90/3T/dP90/3P/c/9z/3P/c/9z/3P/c/9z/3P/cv9y/3L/cv9y/3L/cv9y/3L/cv9x/3H/cf9x/3H/cf9x/3H/cf9x/3D/cP9w/3D/cP9w/3D/cP9w/3D/b/9v/2//b/9v/2//b/9v/2//b/9u/27/bv9u/27/bv9u/27/bv9u/23/bf9t/23/bf9t/23/bf9t/23/bP9s/2z/bP9s/2z/bP9s/2z/bP9r/2v/a/9r/2v/a/9r/2v/a/9r/2r/av9q/2r/av9q/2r/av9q/2r/af9p/2n/af9p/2n/af9p/2n/af9o/2j/aP9o/2j/aP9o/2j/aP9o/2f/Z/9n/2f/Z/9n/2f/Z/9n/2f/Zv9m/2b/Zv9m/2b/Zv9m/2b/Zv9l/2X/Zf9l/2X/Zf9l/2X/Zf9l/2T/ZP9k/2T/ZP9k/2T/ZP9k/2T/Y/9j/2P/Y/9j/2P/Y/9j/2P/Y/9i/2L/Yv9i/2L/Yv9i/2L/Yv9i/2H/Yf9h/2H/Yf9h/2H/Yf9h/2H/YP9g/2D/YP9g/2D/YP9g/2D/YP9f/1//X/9f/1//X/9f/1//X/9f/17/Xv9e/17/Xv9e/17/Xv9e/17/Xf9d/13/Xf9d/13/Xf9d/13/Xf9c/1z/XP9c/1z/XP9c/1z/XP9c/1v/W/9b/1v/W/9b/1v/W/9b/1v/Wv9a/1r/Wv9a/1r/Wv9a/1r/Wv9Z/1n/Wf9Z/1n/Wf9Z/1n/Wf9Z/1j/WP9Y/1j/WP9Y/1j/WP9Y/1j/V/9X/1f/V/9X/1f/V/9X/1f/V/9W/1b/Vv9W/1b/Vv9W/1b/Vv9W/1X/Vf9V/1X/Vf9V/1X/Vf9V/1X/VP9U/1T/VP9U/1T/VP9U/1T/VP9T/1P/U/9T/1P/U/9T/1P/U/9T/1L/Uv9S/1L/Uv9S/1L/Uv9S/1L/Uf9R/1H/Uf9R/1H/Uf9R/1H/Uf9Q/1D/UP9Q/1D/UP9Q/1D/UP9Q/0//T/9P/0//T/9P/0//T/9P/0//Tv9O/07/Tv9O/07/Tv9O/07/Tv9N/03/Tf9N/03/Tf9N/03/Tf9N/0z/TP9M/0z/TP9M/0z/TP9M/0z/S/9L/0v/S/9L/0v/S/9L/0v/S/9K/0r/Sv9K/0r/Sv9K/0r/Sv9K/0n/Sf9J/0n/Sf9J/0n/Sf9J/0n/SP9I/0j/SP9I/0j/SP9I/0j/SP9H/0f/R/9H/0f/R/9H/0f/R/9H/0b/Rv9G/0b/Rv9G/0b/Rv9G/0b/Rf9F/0X/Rf9F/0X/Rf9F/0X/Rf9E/0T/RP9E/0T/RP9E/0T/RP9E/0P/Q/9D/0P/Q/9D/0P/Q/9D/0P/Qv9C/0L/Qv9C/0L/Qv9C/0L/Qv9B/0H/Qf9B/0H/Qf9B/0H/Qf9B/0D/QP9A/0D/QP9A/0D/QP9A/0D/P/8//z//P/8//z//P/8//z//P/4+/j7+Pv4+/j7+Pv4+/j7+Pv49/j3+Pf49/j3+Pf49/j3+Pf49/jz+PP48/jz+PP48/jz+PP48/jz+PL48vjy+PL48vjy+PL48vjy+PL48fjx+PH48fjx+PH48fjx+PH48fjw+PD48Pjw+PD48Pjw+PD48Pjw+O/47/jv+O/47/jv+O/47/jv+O/46/jr+Ov46/jr+Ov46/jr+Ov46/jn+Of45/jn+Of45/jn+Of45/jn+Ob45vjm+Ob45vjm+Ob45vjm+Ob45fjl+OX45fjl+OX45fjl+OX45fjk+OT45Pjk+OT45Pjk+OT45Pjk+OP44/jj+OP44/jj+OP44/jj+OP44vjk=';
  
  // Teslimat tamamlandı sesi (başarı melodisi)
  final String _deliveryCompletedSoundUrl = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACAiI6IjoiOiI6IjoiOiI6IjoiOiI6IjoiOiI6IjoiOiI6IjoiOjYiNiI2IjYiNiI2IjYiNiI2IjYiNiI2IjIiMiIyIjIiMiIyIjIiMiIyIjIiMiIuIi4iLiIuIi4iLiIuIi4iLiIuIi4iKiIqIioiKiIqIioiKiIqIioiKiIqIiYiJiImIiYiJiImIiYiJiImIiYiJiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIeIh4iHiIeIh4iHiIeIh4iHiIeIh4iGiIaIhoiGiIaIhoiGiIaIhoiGiIaIhYiFiIWIhYiFiIWIhYiFiIWIhYiFiISIhIiEiISIhIiEiISIhIiEiISIg4iDiIOIg4iDiIOIg4iDiIOIg4iCiIKIgoiCiIKIgoiCiIKIgoiCiIKIgYiBiIGIgYiBiIGIgYiBiIGIgYiBiICIgIiAiICIgIiAiICIgIiAiICIgIf/h/+H/4f/h/+H/4f/h/+H/4f/h/+G/4b/hv+G/4b/hv+G/4b/hv+G/4b/hf+F/4X/hf+F/4X/hf+F/4X/hf+F/4T/hP+E/4T/hP+E/4T/hP+E/4T/hP+D/4P/g/+D/4P/g/+D/4P/g/+D/4L/gv+C/4L/gv+C/4L/gv+C/4L/gv+B/4H/gf+B/4H/gf+B/4H/gf+B/4D/gP+A/4D/gP+A/4D/gP+A/4D/f/9//3//f/9//3//f/9//3//f/9+/37/fv9+/37/fv9+/37/fv9+/33/ff99/33/ff99/33/ff99/33/fP98/3z/fP98/3z/fP98/3z/fP98/3v/e/97/3v/e/97/3v/e/97/3v/ev96/3r/ev96/3r/ev96/3r/ev96/3n/ef95/3n/ef95/3n/ef95/3n/eP94/3j/eP94/3j/eP94/3j/eP94/3f/d/93/3f/d/93/3f/d/93/3f/dv92/3b/dv92/3b/dv92/3b/dv92/3X/df91/3X/df91/3X/df91/3X/dP90/3T/dP90/3T/dP90/3T/dP90/3P/c/9z/3P/c/9z/3P/c/9z/3P/cv9y/3L/cv9y/3L/cv9y/3L/cv9x/3H/cf9x/3H/cf9x/3H/cf9x/3D/cP9w/3D/cP9w/3D/cP9w/3D/b/9v/2//b/9v/2//b/9v/2//b/9u/27/bv9u/27/bv9u/27/bv9u/23/bf9t/23/bf9t/23/bf9t/23/bP9s/2z/bP9s/2z/bP9s/2z/bP9r/2v/a/9r/2v/a/9r/2v/a/9r/2r/av9q/2r/av9q/2r/av9q/2r/af9p/2n/af9p/2n/af9p/2n/af9o/2j/aP9o/2j/aP9o/2j/aP9o/2f/Z/9n/2f/Z/9n/2f/Z/9n/2f/Zv9m/2b/Zv9m/2b/Zv9m/2b/Zv9l/2X/Zf9l/2X/Zf9l/2X/Zf9l/2T/ZP9k/2T/ZP9k/2T/ZP9k/2T/Y/9j/2P/Y/9j/2P/Y/9j/2P/Y/9i/2L/Yv9i/2L/Yv9i/2L/Yv9i/2H/Yf9h/2H/Yf9h/2H/Yf9h/2H/YP9g/2D/YP9g/2D/YP9g/2D/YP9f/1//X/9f/1//X/9f/1//X/9f/17/Xv9e/17/Xv9e/17/Xv9e/17/Xf9d/13/Xf9d/13/Xf9d/13/Xf9c/1z/XP9c/1z/XP9c/1z/XP9c/1v/W/9b/1v/W/9b/1v/W/9b/1v/Wv9a/1r/Wv9a/1r/Wv9a/1r/Wv9Z/1n/Wf9Z/1n/Wf9Z/1n/Wf9Z/1j/WP9Y/1j/WP9Y/1j/WP9Y/1j/V/9X/1f/V/9X/1f/V/9X/1f/V/9W/1b/Vv9W/1b/Vv9W/1b/Vv9W/1X/Vf9V/1X/Vf9V/1X/Vf9V/1X/VP9U/1T/VP9U/1T/VP9U/1T/VP9T/1P/U/9T/1P/U/9T/1P/U/9T/1L/Uv9S/1L/Uv9S/1L/Uv9S/1L/Uf9R/1H/Uf9R/1H/Uf9R/1H/Uf9Q/1D/UP9Q/1D/UP9Q/1D/UP9Q/0//T/9P/0//T/9P/0//T/9P/0//Tv9O/07/Tv9O/07/Tv9O/07/Tv9N/03/Tf9N/03/Tf9N/03/Tf9N/0z/TP9M/0z/TP9M/0z/TP9M/0z/S/9L/0v/S/9L/0v/S/9L/0v/S/9K/0r/Sv9K/0r/Sv9K/0r/Sv9K/0n/Sf9J/0n/Sf9J/0n/Sf9J/0n/SP9I/0j/SP9I/0j/SP9I/0j/SP9H/0f/R/9H/0f/R/9H/0f/R/9H/0b/Rv9G/0b/Rv9G/0b/Rv9G/0b/Rf9F/0X/Rf9F/0X/Rf9F/0X/Rf9E/0T/RP9E/0T/RP9E/0T/RP9E/0P/Q/9D/0P/Q/9D/0P/Q/9D/0P/Qv9C/0L/Qv9C/0L/Qv9C/0L/Qv9B/0H/Qf9B/0H/Qf9B/0H/Qf9B/0D/QP9A/0D/QP9A/0D/QP9A/0D/P/8//z//P/8//z//P/8//z//P/4+/j7+Pv4+/j7+Pv4+/j7+Pv49/j3+Pf49/j3+Pf49/j3+Pf49/jz+PP48/jz+PP48/jz+PP48/jz+PL48vjy+PL48vjy+PL48vjy+PL48fjx+PH48fjx+PH48fjx+PH48fjw+PD48Pjw+PD48Pjw+PD48Pjw+O/47/jv+O/47/jv+O/47/jv+O/46/jr+Ov46/jr+Ov46/jr+Ov46/jn+Of45/jn+Of45/jn+Of45/jn+Ob45vjm+Ob45vjm+Ob45vjm+Ob45fjl+OX45fjl+OX45fjl+OX45fjk+OT45Pjk+OT45Pjk+OT45Pjk+OP44/jj+OP44/jj+OP44/jj+OP44vjl+OX45fjl+OX45Q==';
  
  // Acil sipariş bildirimi (yüksek öncelikli)
  final String _urgentOrderSoundUrl = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACAlJSUlJSUlJSUlJSUlJSUlJSUlJSUlJSUlJSTlJOUk5STlJOUk5STlJOUk5STlJOUk5STlJKUkpSSlJKUkpSSlJKUkpSSlJKUkpSSlJGUkZSRlJGUkZSRlJGUkZSRlJGUkZSRlJCUkJSQlJCUkJSQlJCUkJSQlJCUkJSQlI+Uj5SPlI+Uj5SPlI+Uj5SPlI+Uj5SOlI6UjpSOlI6UjpSOlI6UjpSOlI6UjpSNlI2UjZSNlI2UjZSNlI2UjZSNlI2UjJSMlIyUjJSMlIyUjJSMlIyUjJSMlIuUi5SLlIuUi5SLlIuUi5SLlIuUi5SKlIqUipSKlIqUipSKlIqUipSKlIqUiZSJlImUiZSJlImUiZSJlImUiZSJlIiUiJSIlIiUiJSIlIiUiJSIlIiUiJSHlIeUh5SHlIeUh5SHlIeUh5SHlIaUhpSGlIaUhpSGlIaUhpSGlIaUhpSFlIWUhZSFlIWUhZSFlIWUhZSFlIWUhJSElISUhJSElISUhJSElISUhJSElIOUg5SDlIOUg5SDlIOUg5SDlIOUg5SClIKUgpSClIKUgpSClIKUgpSClIKUgZSBlIGUgZSBlIGUgZSBlIGUgZSBlICUgJSAlICUgJSAlICUgJSAlICUgJR/lH+Uf5R/lH+Uf5R/lH+Uf5R/lH+Uf5R+lH6UfpR+lH6UfpR+lH6UfpR+lH6UfZR9lH2UfZR9lH2UfZR9lH2UfZR9lH2UfJR8lHyUfJR8lHyUfJR8lHyUfJR8lHuUe5R7lHuUe5R7lHuUe5R7lHuUe5R7lHqUepR6lHqUepR6lHqUepR6lHqUepR5lHmUeZR5lHmUeZR5lHmUeZR5lHmUeJR4lHiUeJR4lHiUeJR4lHiUeJR4lHeUd5R3lHeUd5R3lHeUd5R3lHeUd5R2lHaUdpR2lHaUdpR2lHaUdpR2lHaUdZR1lHWUdZR1lHWUdZR1lHWUdZR1lHSUdJR0lHSUdJR0lHSUdJR0lHSUdJRzlHOUc5RzlHOUc5RzlHOUc5RzlHOUc5RylHKUcpRylHKUcpRylHKUcpRylHKUcZRxlHGUcZRxlHGUcZRxlHGUcZRxlHCUcJRwlHCUcJRwlHCUcJRwlHCUcJRvlG+Ub5RvlG+Ub5RvlG+Ub5RvlG+Ub5RulG6UbpRulG6UbpRulG6UbpRulG6UbZRtlG2UbZRtlG2UbZRtlG2UbZRtlGyUbJRslGyUbJRslGyUbJRslGyUbJRrlGuUa5RrlGuUa5RrlGuUa5RrlGuUapRqlGqUapRqlGqUapRqlGqUapRqlGmUaZRplGmUaZRplGmUaZRplGmUaZRolGiUaJRolGiUaJRolGiUaJRolGiUZ5RnlGeUZ5RnlGeUZ5RnlGeUZ5RnlGaUZpRmlGaUZpRmlGaUZpRmlGaUZpRllGWUZZRllGWUZZRllGWUZZRllGWUZJRklGSUZJRklGSUZJRklGSUZJRklGOUY5RjlGOUY5RjlGOUY5RjlGOUY5RilGKUYpRilGKUYpRilGKUYpRilGKUYZRhlGGUYZRhlGGUYZRhlGGUYZRhlGCUYJRglGCUYJRglGCUYJRglGCUYJRflF+UX5RflF+UX5RflF+UX5RflF+UXpRelF6UXpRelF6UXpRelF6UXpRelF2UXZRdlF2UXZRdlF2UXZRdlF2UXZRclFyUXJRclFyUXJRclFyUXJRclFyUW5RblFuUW5RblFuUW5RblFuUW5RblFqUWpRalFqUWpRalFqUWpRalFqUWpRZlFmUWZRZlFmUWZRZlFmUWZRZlFmUWJRYlFiUWJRYlFiUWJRYlFiUWJRYlFeUV5RXlFeUV5RXlFeUV5RXlFeUV5RWlFaUVpRWlFaUVpRWlFaUVpRWlFaUVZRVlFWUVZRVlFWUVZRVlFWUVZRVlFSUVJRUlFSUVJRUlFSUVJRUlFSUVJRTlFOUU5RTlFOUU5RTlFOUU5RTlFOUUpRSlFKUUpRSlFKUUpRSlFKUUpRSlFGUUZRRlFGUUZRRlFGUUZRRlFGUUZRQlFCUUJRQlFCUUJRQlFCUUJRQlFCUT5RPlE+UT5RPlE+UT5RPlE+UT5RPlE6UTpROlE6UTpROlE6UTpROlE6UTpRNlE2UTZRNlE2UTZRNlE2UTZRNlE2UTJRMlEyUTJRMlEyUTJRMlEyUTJRMlEuUS5RLlEuUS5RLlEuUS5RLlEuUS5RKlEqUSpRKlEqUSpRKlEqUSpRKlEqUSZRJlEmUSZRJlEmUSZRJlEmUSZRJlEiUSJRIlEiUSJRIlEiUSJRIlEiUSJRelE6UTpRelE6UTpROlE6UTpROlE6UUJROlE6UTpROlE6UQ==';
  
  // Toplama noktasına varış sesi
  final String _pickupPointArrivedSoundUrl = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACAhIiEiISIhIiEiISIhIiEiISIhIiEiISIhIiEiISIhIiEiISIg4iDiIOIg4iDiIOIg4iDiIOIg4iDiIKIgoiCiIKIgoiCiIKIgoiCiIKIgoiBiIGIgYiBiIGIgYiBiIGIgYiBiICIgIiAiICIgIiAiICIgIiAiICIgIf/h/+H/4f/h/+H/4f/h/+H/4f/h/+G/4b/hv+G/4b/hv+G/4b/hv+G/4b/hf+F/4X/hf+F/4X/hf+F/4X/hf+F/4T/hP+E/4T/hP+E/4T/hP+E/4T/hP+D/4P/g/+D/4P/g/+D/4P/g/+D/4L/gv+C/4L/gv+C/4L/gv+C/4L/gv+B/4H/gf+B/4H/gf+B/4H/gf+B/4D/gP+A/4D/gP+A/4D/gP+A/4D/f/9//3//f/9//3//f/9//3//f/9+/37/fv9+/37/fv9+/37/fv9+/33/ff99/33/ff99/33/ff99/33/fP98/3z/fP98/3z/fP98/3z/fP98/3v/e/97/3v/e/97/3v/e/97/3v/ev96/3r/ev96/3r/ev96/3r/ev96/3n/ef95/3n/ef95/3n/ef95/3n/eP94/3j/eP94/3j/eP94/3j/eP94/3f/d/93/3f/d/93/3f/d/93/3f/dv92/3b/dv92/3b/dv92/3b/dv92/3X/df91/3X/df91/3X/df91/3X/dP90/3T/dP90/3T/dP90/3T/dP90/3P/c/9z/3P/c/9z/3P/c/9z/3P/cv9y/3L/cv9y/3L/cv9y/3L/cv9x/3H/cf9x/3H/cf9x/3H/cf9x/3D/cP9w/3D/cP9w/3D/cP9w/3D/b/9v/2//b/9v/2//b/9v/2//b/9u/27/bv9u/27/bv9u/27/bv9u/23/bf9t/23/bf9t/23/bf9t/23/bP9s/2z/bP9s/2z/bP9s/2z/bP9r/2v/a/9r/2v/a/9r/2v/a/9r/2r/av9q/2r/av9q/2r/av9q/2r/af9p/2n/af9p/2n/af9p/2n/af9o/2j/aP9o/2j/aP9o/2j/aP9o/2f/Z/9n/2f/Z/9n/2f/Z/9n/2f/Zv9m/2b/Zv9m/2b/Zv9m/2b/Zv9l/2X/Zf9l/2X/Zf9l/2X/Zf9l/2T/ZP9k/2T/ZP9k/2T/ZP9k/2T/Y/9j/2P/Y/9j/2P/Y/9j/2P/Y/9i/2L/Yv9i/2L/Yv9i/2L/Yv9i/2H/Yf9h/2H/Yf9h/2H/Yf9h/2H/YP9g/2D/YP9g/2D/YP9g/2D/YP9f/1//X/9f/1//X/9f/1//X/9f/17/Xv9e/17/Xv9e/17/Xv9e/17/Xf9d/13/Xf9d/13/Xf9d/13/Xf9c/1z/XP9c/1z/XP9c/1z/XP9c/1v/W/9b/1v/W/9b/1v/W/9b/1v/Wv9a/1r/Wv9a/1r/Wv9a/1r/Wv9Z/1n/Wf9Z/1n/Wf9Z/1n/Wf9Z/1j/WP9Y/1j/WP9Y/1j/WP9Y/1j/V/9X/1f/V/9X/1f/V/9X/1f/V/9W/1b/Vv9W/1b/Vv9W/1b/Vv9W/1X/Vf9V/1X/Vf9V/1X/Vf9V/1X/VP9U/1T/VP9U/1T/VP9U/1T/VP9T/1P/U/9T/1P/U/9T/1P/U/9T/1L/Uv9S/1L/Uv9S/1L/Uv9S/1L/Uf9R/1H/Uf9R/1H/Uf9R/1H/Uf9Q/1D/UP9Q/1D/UP9Q/1D/UP9Q/0//T/9P/0//T/9P/0//T/9P/0//Tv9O/07/Tv9O/07/Tv9O/07/Tv9N/03/Tf9N/03/Tf9N/03/Tf9N/0z/TP9M/0z/TP9M/0z/TP9M/0z/S/9L/0v/S/9L/0v/S/9L/0v/S/9K/0r/Sv9K/0r/Sv9K/0r/Sv9K/0n/Sf9J/0n/Sf9J/0n/Sf9J/0n/SP9I/0j/SP9I/0j/SP9I/0j/SP9H/0f/R/9H/0f/R/9H/0f/R/9H/0b/Rv9G/0b/Rv9G/0b/Rv9G/0b/Rf9F/0X/Rf9F/0X/Rf9F/0X/Rf9E/0T/RP9E/0T/RP9E/0T/RP9E/0P/Q/9D/0P/Q/9D/0P/Q/9D/0P/Qv9C/0L/Qv9C/0L/Qv9C/0L/Qv9B/0H/Qf9B/0H/Qf9B/0H/Qf9B/0D/QP9A/0D/QP9A/0D/QP9A/0D/P/8//z//P/8//z//P/8//z//P/4+/j7+Pv4+/j7+Pv4+/j7+Pv49/j3+Pf49/j3+Pf49/j3+Pf49/jz+PP48/jz+PP48/jz+PP48/jz+PL48vjy+PL48vjy+PL48vjy+PL48fjx+PH48fjx+PH48fjx+PH48fjw+PD48Pjw+PD48Pjw+PD48Pjw+O/47/jv+O/47/jv+O/47/jv+O/46/jr+Ov46/jr+Ov46/jr+Ov46/jn+Of45/jn+Of45/jn+Of45/jn+Ob45vjm+Ob45vjm+Ob45vjm+Ob45fjl+OX45fjl+OX45fjl+OX45fjk+OT45Pjk+OT45Pjk+OT45Pjk+OP44/jj+OP44/jj+OP44/jj+OP44vjh+OI=';

  // Bildirim ayarları
  bool _notificationsEnabled = true;
  int _soundVolume = 70; // 0-100 arası

  // HTML Audio elementleri (cache için)
  html.AudioElement? _newOrderAudio;
  html.AudioElement? _approachingAudio;
  html.AudioElement? _completedAudio;
  html.AudioElement? _urgentAudio;
  html.AudioElement? _pickupPointAudio;

  /// Servisi başlat ve ses dosyalarını hazırla
  void initialize() {
    if (!kIsWeb) {
      debugPrint('⚠️ NotificationService: Web dışı platformda çalışıyor - Sesler devre dışı');
      return;
    }

    try {
      _newOrderAudio = html.AudioElement(_newOrderAssignedSoundUrl);
      _approachingAudio = html.AudioElement(_deliveryApproachingSoundUrl);
      _completedAudio = html.AudioElement(_deliveryCompletedSoundUrl);
      _urgentAudio = html.AudioElement(_urgentOrderSoundUrl);
      _pickupPointAudio = html.AudioElement(_pickupPointArrivedSoundUrl);
      
      debugPrint('✅ NotificationService başlatıldı (Kurye Uygulaması)');
    } catch (e) {
      debugPrint('❌ Ses dosyaları yüklenirken hata: $e');
    }
  }

  /// Yeni sipariş atandığında çalınacak ses
  void playNewOrderAssignedSound() {
    if (!_notificationsEnabled || !kIsWeb) {
      if (!kIsWeb) {
        debugPrint('ℹ️ Mobil platformda ses desteği henüz eklenmedi');
      }
      return;
    }

    try {
      _newOrderAudio?.volume = _soundVolume / 100;
      _newOrderAudio?.play();
      debugPrint('🔔 YENİ SİPARİŞ ATANDI SESİ ÇALINIYOR (Volume: $_soundVolume%)');
    } catch (e) {
      debugPrint('❌ Yeni sipariş sesi çalarken hata: $e');
    }
  }

  /// Müşteriye yaklaşıldığında çalınacak ses
  void playApproachingCustomerSound() {
    if (!_notificationsEnabled || !kIsWeb) {
      if (!kIsWeb) {
        debugPrint('ℹ️ Mobil platformda ses desteği henüz eklenmedi');
      }
      return;
    }

    try {
      _approachingAudio?.volume = _soundVolume / 100;
      _approachingAudio?.play();
      debugPrint('📍 MÜŞTERİYE YAKLAŞMA SESİ ÇALINIYOR (Volume: $_soundVolume%)');
    } catch (e) {
      debugPrint('❌ Yaklaşma sesi çalarken hata: $e');
    }
  }

  /// Teslimat tamamlandığında çalınacak ses
  void playDeliveryCompletedSound() {
    if (!_notificationsEnabled || !kIsWeb) {
      if (!kIsWeb) {
        debugPrint('ℹ️ Mobil platformda ses desteği henüz eklenmedi');
      }
      return;
    }

    try {
      _completedAudio?.volume = _soundVolume / 100;
      _completedAudio?.play();
      debugPrint('✅ TESLİMAT TAMAMLANDI SESİ ÇALINIYOR (Volume: $_soundVolume%)');
    } catch (e) {
      debugPrint('❌ Teslimat tamamlandı sesi çalarken hata: $e');
    }
  }

  /// Acil sipariş bildirimi
  void playUrgentOrderSound() {
    if (!_notificationsEnabled || !kIsWeb) {
      if (!kIsWeb) {
        debugPrint('ℹ️ Mobil platformda ses desteği henüz eklenmedi');
      }
      return;
    }

    try {
      _urgentAudio?.volume = (_soundVolume + 20).clamp(0, 100) / 100; // Acil siparişler biraz daha yüksek sesle
      _urgentAudio?.play();
      debugPrint('🚨 ACİL SİPARİŞ SESİ ÇALINIYOR (Volume: ${(_soundVolume + 20).clamp(0, 100)}%)');
    } catch (e) {
      debugPrint('❌ Acil sipariş sesi çalarken hata: $e');
    }
  }

  /// Toplama noktasına varıldığında çalınacak ses
  void playPickupPointArrivedSound() {
    if (!_notificationsEnabled || !kIsWeb) {
      if (!kIsWeb) {
        debugPrint('ℹ️ Mobil platformda ses desteği henüz eklenmedi');
      }
      return;
    }

    try {
      _pickupPointAudio?.volume = _soundVolume / 100;
      _pickupPointAudio?.play();
      debugPrint('📦 TOPLAMA NOKTASI SESİ ÇALINIYOR (Volume: $_soundVolume%)');
    } catch (e) {
      debugPrint('❌ Toplama noktası sesi çalarken hata: $e');
    }
  }

  /// Test sesi çal (tüm sesleri sırayla)
  void playTestSound() {
    if (!_notificationsEnabled || !kIsWeb) {
      if (!kIsWeb) {
        debugPrint('ℹ️ Mobil platformda ses desteği henüz eklenmedi');
      }
      return;
    }

    debugPrint('🔊 TEST SESLERİ ÇALINIYOR...');
    
    playNewOrderAssignedSound();
    Future.delayed(const Duration(seconds: 2), () => playApproachingCustomerSound());
    Future.delayed(const Duration(seconds: 4), () => playPickupPointArrivedSound());
    Future.delayed(const Duration(seconds: 6), () => playDeliveryCompletedSound());
  }

  // Getter ve Setter metodları
  bool get notificationsEnabled => _notificationsEnabled;
  int get soundVolume => _soundVolume;

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    debugPrint('🔔 Bildirimler ${enabled ? 'açıldı' : 'kapatıldı'}');
  }

  void setSoundVolume(int volume) {
    _soundVolume = volume.clamp(0, 100);
    debugPrint('🔊 Ses seviyesi: $_soundVolume%');
  }

  /// Bildirimleri tamamen kapat
  void dispose() {
    _newOrderAudio?.pause();
    _approachingAudio?.pause();
    _completedAudio?.pause();
    _urgentAudio?.pause();
    _pickupPointAudio?.pause();
    
    _newOrderAudio = null;
    _approachingAudio = null;
    _completedAudio = null;
    _urgentAudio = null;
    _pickupPointAudio = null;
    
    debugPrint('🔕 NotificationService kapatıldı');
  }
}
