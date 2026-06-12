import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Perfil de tolerancia para letras con formas especiales.
enum AlfabetizacionTrazoPerfil {
  estandar,
  vocalI,
  vocalU,
}

/// Motor unificado de validación de trazos para lecciones de escritura.
class AlfabetizacionTrazoValidator {
  AlfabetizacionTrazoValidator._();

  /// Valida trazo sobre una letra centrada (vocales, abecedario).
  static bool validarLetraEnLienzo({
    required List<Offset> puntosRaw,
    required String letra,
    required Size canvasSize,
    AlfabetizacionTrazoPerfil perfil = AlfabetizacionTrazoPerfil.estandar,
  }) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return false;

    if (perfil == AlfabetizacionTrazoPerfil.vocalI &&
        _formaVerticalEnLienzo(puntosRaw, canvasSize)) {
      return true;
    }
    if (perfil == AlfabetizacionTrazoPerfil.vocalU &&
        _formaUEnLienzo(puntosRaw, canvasSize)) {
      return true;
    }

    return validarTextoEnLienzo(
      puntosRaw: puntosRaw,
      texto: letra,
      canvasSize: canvasSize,
      fontSize: canvasSize.height * 0.7,
      letterSpacing: 0,
      esLetraUnica: true,
    );
  }

  /// Valida trazo sobre texto centrado (sílabas, palabras, frases).
  static bool validarTextoEnLienzo({
    required List<Offset> puntosRaw,
    required String texto,
    required Size canvasSize,
    required double fontSize,
    double letterSpacing = 4,
    bool esLetraUnica = false,
  }) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return false;

    final puntos = _puntosFinitos(puntosRaw);
    final letras = texto.replaceAll(' ', '');
    final nLetras = math.max(letras.length, 1);

    if (puntos.length < 6 + nLetras * 2) return false;

    final layout = _layoutTexto(
      texto: texto,
      canvasSize: canvasSize,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
    );
    if (layout == null || layout.regiones.isEmpty) return false;

    final umbral = _umbralDistancia(canvasSize, esLetraUnica);
    final trazosUsuario = _segmentarTrazos(puntosRaw);
    if (trazosUsuario.isEmpty) return false;

    final muestras = _generarMuestras(layout.regiones);
    if (muestras.isEmpty) return false;

    var muestrasCubiertas = 0;
    for (final muestra in muestras) {
      if (_cercaDePolilineas(muestra, trazosUsuario, umbral)) {
        muestrasCubiertas++;
      }
    }
    final cobertura = muestrasCubiertas / muestras.length;

    var puntosEnModelo = 0;
    final regionesInfladas =
        layout.regiones.map((r) => r.inflate(umbral * 0.85)).toList();
    for (final p in puntos) {
      if (regionesInfladas.any((r) => r.contains(p))) {
        puntosEnModelo++;
      } else if (_distanciaMinimaARegiones(p, layout.regiones) <= umbral) {
        puntosEnModelo++;
      }
    }
    final precision = puntosEnModelo / puntos.length;

    final boxTrazo = _bounds(puntos);
    final boxTexto = layout.cajaTexto;
    if (!_solapamientoRazonable(boxTrazo, boxTexto)) return false;
    if (_esGarabato(puntos, trazosUsuario, boxTrazo, boxTexto, canvasSize)) {
      return false;
    }

    if (!_coberturaPorLetra(layout.regionesPorIndice, trazosUsuario, umbral)) {
      return false;
    }

    final minCobertura = esLetraUnica
        ? 0.38
        : nLetras > 14
            ? 0.34
            : nLetras > 8
                ? 0.36
                : 0.4;
    final minPrecision = esLetraUnica
        ? 0.28
        : nLetras > 14
            ? 0.24
            : nLetras > 8
                ? 0.26
                : 0.28;

    return cobertura >= minCobertura && precision >= minPrecision;
  }

  /// Valida trazo contra contorno relativo 0–1 (respaldo opcional).
  static bool validarContornoRelativo({
    required List<Offset> puntosRaw,
    required List<Offset> contornoRelativo,
    required Size canvasSize,
  }) {
    if (canvasSize.width <= 0 ||
        canvasSize.height <= 0 ||
        contornoRelativo.length < 2) {
      return false;
    }

    final puntos = _puntosFinitos(puntosRaw);
    if (puntos.length < 8) return false;

    final modelo = contornoRelativo
        .map(
          (p) => Offset(
            p.dx * canvasSize.width,
            p.dy * canvasSize.height,
          ),
        )
        .toList();

    final umbral = _umbralDistancia(canvasSize, true);
    final trazosUsuario = _segmentarTrazos(puntosRaw);
    final muestrasModelo = _densificarPolyline(modelo, umbral * 0.6);

    final cobertura = _ratioCercaDePolilineas(muestrasModelo, trazosUsuario, umbral);
    final precision = _ratioPuntosCercaDePolyline(puntos, modelo, umbral * 1.15);

    final boxUser = _bounds(puntos);
    final boxModelo = _bounds(modelo).inflate(umbral);
    if (!_solapamientoRazonable(boxUser, boxModelo)) return false;
    if (_area(boxUser) / math.max(_area(boxModelo), 1) > 5.5) return false;

    return cobertura >= 0.4 && precision >= 0.32;
  }

  static double _umbralDistancia(Size canvasSize, bool letraUnica) {
    final base = math.min(canvasSize.width, canvasSize.height);
    return math.max(letraUnica ? 16.0 : 12.0, base * (letraUnica ? 0.1 : 0.085));
  }

  static bool _formaVerticalEnLienzo(List<Offset> raw, Size canvasSize) {
    final puntos = _puntosFinitos(raw);
    if (puntos.length < 6) return false;
    final box = _bounds(puntos);
    if (box.height < canvasSize.height * 0.25) return false;
    if (box.width > canvasSize.width * 0.35) return false;
    if (box.height / math.max(box.width, 1) < 1.4) return false;

    final cx = puntos.map((p) => p.dx).reduce((a, b) => a + b) / puntos.length;
    final alineados =
        puntos.where((p) => (p.dx - cx).abs() <= box.width * 0.55 + 8).length;
    return alineados / puntos.length >= 0.5;
  }

  static bool _formaUEnLienzo(List<Offset> raw, Size canvasSize) {
    final puntos = _puntosFinitos(raw);
    if (puntos.length < 8) return false;
    final box = _bounds(puntos);
    if (box.height < canvasSize.height * 0.22) return false;
    if (box.width < canvasSize.width * 0.12) return false;
    if (box.width / math.max(box.height, 1) > 2.6) return false;

    final tercio = box.width / 3;
    final izq = puntos.where((p) => p.dx <= box.left + tercio).length;
    final der = puntos.where((p) => p.dx >= box.right - tercio).length;
    final fondo = puntos.where((p) => p.dy >= box.top + box.height * 0.45).length;
    return izq >= 2 && der >= 2 && fondo / puntos.length >= 0.12;
  }

  static _LayoutTexto? _layoutTexto({
    required String texto,
    required Size canvasSize,
    required double fontSize,
    required double letterSpacing,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasSize.width);

    final offset = Offset(
      (canvasSize.width - painter.width) / 2,
      (canvasSize.height - painter.height) / 2,
    );

    final regiones = <Rect>[];
    final regionesPorIndice = <int, List<Rect>>{};

    for (var i = 0; i < texto.length; i++) {
      if (texto[i] == ' ') continue;
      var cajas = painter.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      if (cajas.isEmpty) {
        final fallback = _rectFallback(painter, texto, i, offset);
        if (fallback != null) {
          regiones.add(fallback);
          regionesPorIndice.putIfAbsent(i, () => []).add(fallback);
        }
        continue;
      }
      for (final caja in cajas) {
        final rect = Rect.fromLTRB(
          offset.dx + caja.left,
          offset.dy + caja.top,
          offset.dx + caja.right,
          offset.dy + caja.bottom,
        );
        regiones.add(rect);
        regionesPorIndice.putIfAbsent(i, () => []).add(rect);
      }
    }

    if (regiones.isEmpty) return null;

    return _LayoutTexto(
      regiones: regiones,
      regionesPorIndice: regionesPorIndice,
      cajaTexto: _union(regiones),
    );
  }

  static Rect? _rectFallback(
    TextPainter painter,
    String texto,
    int indice,
    Offset offset,
  ) {
    final letras = texto.replaceAll(' ', '');
    if (letras.isEmpty) return null;

    final anchoLetra = painter.width / letras.length;
    var idxLetra = 0;
    for (var i = 0; i < indice; i++) {
      if (texto[i] != ' ') idxLetra++;
    }
    final left = idxLetra * anchoLetra;
    return Rect.fromLTRB(
      offset.dx + left,
      offset.dy,
      offset.dx + left + anchoLetra,
      offset.dy + painter.height,
    );
  }

  static List<Offset> _generarMuestras(List<Rect> regiones) {
    final muestras = <Offset>[];
    for (final r in regiones) {
      if (r.width < 2 || r.height < 2) continue;
      muestras.add(r.center);
      final inset = Rect.fromLTRB(
        r.left + r.width * 0.15,
        r.top + r.height * 0.15,
        r.right - r.width * 0.15,
        r.bottom - r.height * 0.15,
      );
      if (inset.width > 1 && inset.height > 1) {
        muestras.addAll([
          inset.topLeft,
          inset.topRight,
          inset.bottomLeft,
          inset.bottomRight,
          Offset(inset.center.dx, inset.top),
          Offset(inset.center.dx, inset.bottom),
          Offset(inset.left, inset.center.dy),
          Offset(inset.right, inset.center.dy),
        ]);
      }
    }
    return muestras;
  }

  static bool _coberturaPorLetra(
    Map<int, List<Rect>> regionesPorIndice,
    List<List<Offset>> trazos,
    double umbral,
  ) {
    if (regionesPorIndice.isEmpty) return true;

    var letrasOk = 0;
    for (final rects in regionesPorIndice.values) {
      final muestras = _generarMuestras(rects);
      if (muestras.isEmpty) {
        letrasOk++;
        continue;
      }
      var hits = 0;
      for (final m in muestras) {
        if (_cercaDePolilineas(m, trazos, umbral)) hits++;
      }
      final ratio = hits / muestras.length;
      if (ratio >= 0.15 || (muestras.length <= 4 && hits >= 1)) {
        letrasOk++;
      }
    }
    return letrasOk >= regionesPorIndice.length * 0.7;
  }

  static bool _esGarabato(
    List<Offset> puntos,
    List<List<Offset>> trazos,
    Rect boxTrazo,
    Rect boxTexto,
    Size canvas,
  ) {
    final areaTrazo = _area(boxTrazo);
    final areaTexto = math.max(_area(boxTexto), 1.0);
    if (areaTrazo / areaTexto > 6.5) return true;

    final longitud = _longitudPolilineas(trazos);
    final diagonal = math.sqrt(
      canvas.width * canvas.width + canvas.height * canvas.height,
    );
    if (longitud > diagonal * 7) return true;

    final fuera = puntos
        .where(
          (p) => _distanciaMinimaARegiones(p, [boxTexto.inflate(20)]) > 24,
        )
        .length;
    if (fuera / puntos.length > 0.55 && areaTrazo / areaTexto > 3.5) {
      return true;
    }

    return false;
  }

  static double _longitudPolilineas(List<List<Offset>> trazos) {
    var total = 0.0;
    for (final trazo in trazos) {
      for (var i = 1; i < trazo.length; i++) {
        total += (trazo[i] - trazo[i - 1]).distance;
      }
    }
    return total;
  }

  static List<List<Offset>> _segmentarTrazos(List<Offset> raw) {
    final trazos = <List<Offset>>[];
    var actual = <Offset>[];
    for (final p in raw) {
      if (!p.dx.isFinite || !p.dy.isFinite) {
        if (actual.length >= 2) trazos.add(actual);
        actual = [];
        continue;
      }
      actual.add(p);
    }
    if (actual.length >= 2) trazos.add(actual);
    return trazos;
  }

  static List<Offset> _densificarPolyline(List<Offset> pts, double paso) {
    if (pts.length < 2) return pts;
    final out = <Offset>[];
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final dist = (b - a).distance;
      final steps = math.max(1, (dist / paso).ceil());
      for (var s = 0; s <= steps; s++) {
        final t = s / steps;
        out.add(Offset(
          a.dx + (b.dx - a.dx) * t,
          a.dy + (b.dy - a.dy) * t,
        ));
      }
    }
    return out;
  }

  static bool _cercaDePolilineas(
    Offset p,
    List<List<Offset>> trazos,
    double umbral,
  ) {
    final umbral2 = umbral * umbral;
    for (final trazo in trazos) {
      for (var i = 1; i < trazo.length; i++) {
        final d = _distanciaPuntoASegmento(p, trazo[i - 1], trazo[i]);
        if (d * d <= umbral2) return true;
      }
    }
    return false;
  }

  static double _ratioCercaDePolilineas(
    List<Offset> muestras,
    List<List<Offset>> trazos,
    double umbral,
  ) {
    if (muestras.isEmpty) return 0;
    var ok = 0;
    for (final m in muestras) {
      if (_cercaDePolilineas(m, trazos, umbral)) ok++;
    }
    return ok / muestras.length;
  }

  static double _ratioPuntosCercaDePolyline(
    List<Offset> puntos,
    List<Offset> polyline,
    double umbral,
  ) {
    if (puntos.isEmpty || polyline.length < 2) return 0;
    var ok = 0;
    for (final p in puntos) {
      var min = double.infinity;
      for (var i = 1; i < polyline.length; i++) {
        final d = _distanciaPuntoASegmento(p, polyline[i - 1], polyline[i]);
        if (d < min) min = d;
      }
      if (min <= umbral) ok++;
    }
    return ok / puntos.length;
  }

  static double _distanciaMinimaARegiones(Offset p, List<Rect> regiones) {
    var min = double.infinity;
    for (final r in regiones) {
      if (r.contains(p)) return 0;
      final dx = p.dx < r.left
          ? r.left - p.dx
          : (p.dx > r.right ? p.dx - r.right : 0.0);
      final dy = p.dy < r.top
          ? r.top - p.dy
          : (p.dy > r.bottom ? p.dy - r.bottom : 0.0);
      final dist = math.sqrt((dx * dx) + (dy * dy));
      if (dist < min) min = dist;
    }
    return min;
  }

  static double _distanciaPuntoASegmento(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final ab2 = (ab.dx * ab.dx) + (ab.dy * ab.dy);
    if (ab2 <= 1e-9) return (p - a).distance;
    final t = ((ap.dx * ab.dx) + (ap.dy * ab.dy)) / ab2;
    final tc = t.clamp(0.0, 1.0);
    final proyeccion = Offset(a.dx + ab.dx * tc, a.dy + ab.dy * tc);
    return (p - proyeccion).distance;
  }

  static bool _solapamientoRazonable(Rect trazo, Rect texto) {
    final inter = trazo.intersect(texto);
    if (inter.isEmpty) return false;

    final areaTexto = math.max(_area(texto), 1.0);
    final areaInter = _area(inter);
    if (areaInter / areaTexto < 0.25) return false;

    final areaTrazo = math.max(_area(trazo), 1.0);
    if (areaTrazo / areaTexto > 6.5) return false;

    return true;
  }

  static double _area(Rect r) => r.width * r.height;

  static List<Offset> _puntosFinitos(List<Offset> raw) =>
      raw.where((p) => p.dx.isFinite && p.dy.isFinite).toList();

  static Rect _union(List<Rect> rects) {
    var left = rects.first.left;
    var top = rects.first.top;
    var right = rects.first.right;
    var bottom = rects.first.bottom;
    for (final r in rects.skip(1)) {
      left = math.min(left, r.left);
      top = math.min(top, r.top);
      right = math.max(right, r.right);
      bottom = math.max(bottom, r.bottom);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Rect _bounds(List<Offset> pts) {
    var left = pts.first.dx;
    var right = pts.first.dx;
    var top = pts.first.dy;
    var bottom = pts.first.dy;
    for (final p in pts) {
      left = math.min(left, p.dx);
      right = math.max(right, p.dx);
      top = math.min(top, p.dy);
      bottom = math.max(bottom, p.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class _LayoutTexto {
  const _LayoutTexto({
    required this.regiones,
    required this.regionesPorIndice,
    required this.cajaTexto,
  });

  final List<Rect> regiones;
  final Map<int, List<Rect>> regionesPorIndice;
  final Rect cajaTexto;
}
