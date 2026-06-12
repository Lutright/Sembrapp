import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Perfil de tolerancia para letras con formas especiales.
enum AlfabetizacionTrazoPerfil {
  estandar,
  vocalI,
  vocalU,
}

/// Resultado de validación (útil para depuración).
class AlfabetizacionTrazoResultado {
  const AlfabetizacionTrazoResultado({
    required this.valido,
    required this.motivo,
  });

  final bool valido;
  final String motivo;
}

/// Motor unificado de validación de trazos para lecciones de escritura.
class AlfabetizacionTrazoValidator {
  AlfabetizacionTrazoValidator._();

  static bool validarLetraEnLienzo({
    required List<Offset> puntosRaw,
    required String letra,
    required Size canvasSize,
    AlfabetizacionTrazoPerfil perfil = AlfabetizacionTrazoPerfil.estandar,
  }) {
    return evaluarLetraEnLienzo(
      puntosRaw: puntosRaw,
      letra: letra,
      canvasSize: canvasSize,
      perfil: perfil,
    ).valido;
  }

  static bool validarTextoEnLienzo({
    required List<Offset> puntosRaw,
    required String texto,
    required Size canvasSize,
    required double fontSize,
    double letterSpacing = 4,
    bool esLetraUnica = false,
  }) {
    return evaluarTextoEnLienzo(
      puntosRaw: puntosRaw,
      texto: texto,
      canvasSize: canvasSize,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      esLetraUnica: esLetraUnica,
    ).valido;
  }

  static AlfabetizacionTrazoResultado evaluarLetraEnLienzo({
    required List<Offset> puntosRaw,
    required String letra,
    required Size canvasSize,
    AlfabetizacionTrazoPerfil perfil = AlfabetizacionTrazoPerfil.estandar,
  }) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'lienzo_sin_medidas',
      );
    }

    final base = evaluarTextoEnLienzo(
      puntosRaw: puntosRaw,
      texto: letra,
      canvasSize: canvasSize,
      fontSize: canvasSize.height * 0.7,
      letterSpacing: 0,
      esLetraUnica: true,
      perfil: perfil,
    );
    if (base.valido) return base;

    // Perfiles I/U: solo aceptar si además hay forma reconocible + algo de trazo
    // sobre la letra (evita línea/circulo sueltos en cualquier parte del lienzo).
    if (perfil == AlfabetizacionTrazoPerfil.vocalI &&
        _formaVerticalEnLienzo(puntosRaw, canvasSize)) {
      return _revalidarFormaEspecial(
        puntosRaw: puntosRaw,
        letra: letra,
        canvasSize: canvasSize,
        fontSize: canvasSize.height * 0.7,
      );
    }
    if (perfil == AlfabetizacionTrazoPerfil.vocalU &&
        _formaUEnLienzo(puntosRaw, canvasSize)) {
      return _revalidarFormaEspecial(
        puntosRaw: puntosRaw,
        letra: letra,
        canvasSize: canvasSize,
        fontSize: canvasSize.height * 0.7,
      );
    }

    return base;
  }

  static AlfabetizacionTrazoResultado evaluarTextoEnLienzo({
    required List<Offset> puntosRaw,
    required String texto,
    required Size canvasSize,
    required double fontSize,
    double letterSpacing = 4,
    bool esLetraUnica = false,
    AlfabetizacionTrazoPerfil perfil = AlfabetizacionTrazoPerfil.estandar,
  }) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'lienzo_sin_medidas',
      );
    }

    final puntos = _puntosFinitos(puntosRaw);
    final letras = texto.replaceAll(' ', '');
    final nLetras = math.max(letras.length, 1);

    if (puntos.length < 10 + nLetras * 4) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'pocos_puntos',
      );
    }

    final layout = _layoutTexto(
      texto: texto,
      canvasSize: canvasSize,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
    );
    if (layout == null || layout.regiones.isEmpty) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'sin_regiones_texto',
      );
    }

    final trazos = _segmentarTrazos(puntosRaw);
    if (trazos.isEmpty) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'sin_trazos',
      );
    }

    final radioCercania = _radioCercania(canvasSize, esLetraUnica);
    final margenTight = math.max(4.0, radioCercania * 0.35);
    final margenLoose = math.max(8.0, radioCercania * 0.75);
    final regionesTight =
        layout.regiones.map((r) => r.inflate(margenTight)).toList();
    final regionesLoose =
        layout.regiones.map((r) => r.inflate(margenLoose)).toList();
    final cajaLoose = layout.cajaTexto.inflate(margenLoose);

    final muestras = _generarMuestras(layout.regiones);
    if (muestras.isEmpty) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'sin_muestras',
      );
    }

    var muestrasCubiertas = 0;
    for (final m in muestras) {
      if (_cercaDePolilineas(m, trazos, radioCercania)) muestrasCubiertas++;
    }
    final cobertura = muestrasCubiertas / muestras.length;

    var puntosEnModelo = 0;
    var puntosFuera = 0;
    for (final p in puntos) {
      if (regionesTight.any((r) => r.contains(p))) {
        puntosEnModelo++;
      } else if (_distanciaMinimaARegiones(p, regionesLoose) <= margenLoose) {
        puntosEnModelo++;
      } else {
        puntosFuera++;
      }
    }
    final precision = puntosEnModelo / puntos.length;
    final fraccionFuera = puntosFuera / puntos.length;

    final boxTrazo = _bounds(puntos);
    final boxTexto = layout.cajaTexto;
    final areaTrazo = _area(boxTrazo);
    final areaTexto = math.max(_area(boxTexto), 1.0);
    final ratioArea = areaTrazo / areaTexto;

    if (!_solapamientoMinimo(boxTrazo, boxTexto)) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'sin_solapamiento',
      );
    }

    if (ratioArea > 2.8) {
      return AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'area_excesiva_${ratioArea.toStringAsFixed(1)}',
      );
    }

    if (fraccionFuera > 0.42) {
      return AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'trazo_fuera_modelo_${(fraccionFuera * 100).toStringAsFixed(0)}',
      );
    }

    final longitud = _longitudPolilineas(trazos);
    final complejidad = longitud / math.max(math.sqrt(areaTrazo), 1.0);
    if (complejidad > 11.5) {
      return AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'garabato_complejo_${complejidad.toStringAsFixed(1)}',
      );
    }

    if (_esTrazoLinealSobreTexto(puntos, layout.cajaTexto, nLetras)) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'trazo_lineal',
      );
    }

    if (perfil == AlfabetizacionTrazoPerfil.estandar &&
        !_coberturaVerticalPorLetra(
          layout.regionesPorIndice,
          trazos,
          radioCercania,
        )) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'trazo_superficial',
      );
    }

    if (!_todasLasLetrasTrazadas(
      layout.regionesPorIndice,
      trazos,
      radioCercania,
      margenTight,
      puntos.length,
    )) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'letras_sin_trazar',
      );
    }

    // Puntos dentro de caja suelta del texto (evita trazo solo en esquina).
    final puntosEnCaja =
        puntos.where((p) => cajaLoose.contains(p)).length / puntos.length;
    if (puntosEnCaja < 0.55) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'trazo_lejos_del_texto',
      );
    }

    final minCobertura = _minCobertura(nLetras, esLetraUnica, perfil);
    final minPrecision = _minPrecision(nLetras, esLetraUnica, perfil);

    if (cobertura < minCobertura) {
      return AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'cobertura_baja_${(cobertura * 100).toStringAsFixed(0)}',
      );
    }
    if (precision < minPrecision) {
      return AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'precision_baja_${(precision * 100).toStringAsFixed(0)}',
      );
    }

    return const AlfabetizacionTrazoResultado(valido: true, motivo: 'ok');
  }

  static AlfabetizacionTrazoResultado _revalidarFormaEspecial({
    required List<Offset> puntosRaw,
    required String letra,
    required Size canvasSize,
    required double fontSize,
  }) {
    final layout = _layoutTexto(
      texto: letra,
      canvasSize: canvasSize,
      fontSize: fontSize,
      letterSpacing: 0,
    );
    if (layout == null) {
      return const AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'forma_sin_layout',
      );
    }

    final puntos = _puntosFinitos(puntosRaw);
    final margen = math.max(6.0, canvasSize.shortestSide * 0.04);
    final regiones = layout.regiones.map((r) => r.inflate(margen)).toList();
    final enModelo =
        puntos.where((p) => regiones.any((r) => r.contains(p))).length;
    final ratio = enModelo / puntos.length;

    if (ratio < 0.45) {
      return AlfabetizacionTrazoResultado(
        valido: false,
        motivo: 'forma_fuera_letra_${(ratio * 100).toStringAsFixed(0)}',
      );
    }

    return const AlfabetizacionTrazoResultado(valido: true, motivo: 'forma_ok');
  }

  static double _minCobertura(
    int nLetras,
    bool esLetraUnica,
    AlfabetizacionTrazoPerfil perfil,
  ) {
    if (perfil != AlfabetizacionTrazoPerfil.estandar) return 0.5;
    if (esLetraUnica) return 0.58;
    if (nLetras > 12) return 0.5;
    if (nLetras > 6) return 0.52;
    return 0.55;
  }

  static double _minPrecision(
    int nLetras,
    bool esLetraUnica,
    AlfabetizacionTrazoPerfil perfil,
  ) {
    if (perfil != AlfabetizacionTrazoPerfil.estandar) return 0.5;
    if (esLetraUnica) return 0.55;
    if (nLetras > 12) return 0.48;
    if (nLetras > 6) return 0.5;
    return 0.52;
  }

  static bool _esTrazoLinealSobreTexto(
    List<Offset> puntos,
    Rect cajaTexto,
    int nLetras,
  ) {
    if (puntos.length < 8 || cajaTexto.isEmpty) return false;
    final box = _bounds(puntos);
    final alturaRel = box.height / math.max(cajaTexto.height, 1.0);
    final anchoRel = box.width / math.max(cajaTexto.width, 1.0);

    if (nLetras > 1 && alturaRel < 0.38 && anchoRel > 0.65) return true;
    if (nLetras == 1 && alturaRel < 0.22 && anchoRel > 0.55) return true;
    if (nLetras == 1 && anchoRel < 0.22 && alturaRel > 0.55) return false;

    final cy = cajaTexto.center.dy;
    final enFranjaHorizontal = puntos
            .where(
              (p) =>
                  (p.dy - cy).abs() <= cajaTexto.height * 0.18 &&
                  cajaTexto.inflate(4).contains(p),
            )
            .length /
        puntos.length;
    if (nLetras > 1 && enFranjaHorizontal > 0.72 && alturaRel < 0.45) {
      return true;
    }
    return false;
  }

  static bool _coberturaVerticalPorLetra(
    Map<int, List<Rect>> regionesPorIndice,
    List<List<Offset>> trazos,
    double radioCercania,
  ) {
    for (final rects in regionesPorIndice.values) {
      final rect = _union(rects);
      if (rect.height < 18) continue;

      final tercio = rect.height / 3;
      final bandas = [
        Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + tercio),
        Rect.fromLTRB(
          rect.left,
          rect.top + tercio,
          rect.right,
          rect.top + tercio * 2,
        ),
        Rect.fromLTRB(
          rect.left,
          rect.top + tercio * 2,
          rect.right,
          rect.bottom,
        ),
      ];

      var bandasCubiertas = 0;
      for (final banda in bandas) {
        final muestras = _generarMuestras([banda]);
        final cubiertas = muestras
            .where((m) => _cercaDePolilineas(m, trazos, radioCercania))
            .length;
        if (muestras.isEmpty) continue;
        if (cubiertas / muestras.length >= 0.34) bandasCubiertas++;
      }
      if (bandasCubiertas < 2) return false;
    }
    return true;
  }

  static double _radioCercania(Size canvasSize, bool letraUnica) {
    final base = canvasSize.shortestSide;
    final factor = letraUnica ? 0.045 : 0.04;
    return base * factor.clamp(0.032, 0.055);
  }

  static bool _formaVerticalEnLienzo(List<Offset> raw, Size canvasSize) {
    final puntos = _puntosFinitos(raw);
    if (puntos.length < 10) return false;
    final box = _bounds(puntos);
    if (box.height < canvasSize.height * 0.28) return false;
    if (box.width > canvasSize.width * 0.28) return false;
    if (box.height / math.max(box.width, 1) < 1.8) return false;

    final cx = puntos.map((p) => p.dx).reduce((a, b) => a + b) / puntos.length;
    final alineados =
        puntos.where((p) => (p.dx - cx).abs() <= box.width * 0.35 + 6).length;
    return alineados / puntos.length >= 0.62;
  }

  static bool _formaUEnLienzo(List<Offset> raw, Size canvasSize) {
    final puntos = _puntosFinitos(raw);
    if (puntos.length < 12) return false;
    final box = _bounds(puntos);
    if (box.height < canvasSize.height * 0.25) return false;
    if (box.width < canvasSize.width * 0.14) return false;
    if (box.width / math.max(box.height, 1) > 2.2) return false;

    final tercio = box.width / 3;
    final izq = puntos.where((p) => p.dx <= box.left + tercio).length;
    final der = puntos.where((p) => p.dx >= box.right - tercio).length;
    final fondo = puntos.where((p) => p.dy >= box.top + box.height * 0.5).length;
    return izq >= 3 && der >= 3 && fondo / puntos.length >= 0.18;
  }

  static bool _todasLasLetrasTrazadas(
    Map<int, List<Rect>> regionesPorIndice,
    List<List<Offset>> trazos,
    double radioCercania,
    double margenTight,
    int totalPuntos,
  ) {
    if (regionesPorIndice.isEmpty) return false;

    final minPuntosPorLetra = math.max(6, (totalPuntos * 0.06).round());

    for (final rects in regionesPorIndice.values) {
      final tight = rects.map((r) => r.inflate(margenTight)).toList();
      final muestras = _generarMuestras(rects);
      var hitsMuestra = 0;
      for (final m in muestras) {
        if (_cercaDePolilineas(m, trazos, radioCercania)) hitsMuestra++;
      }
      final ratioMuestra =
          muestras.isEmpty ? 0.0 : hitsMuestra / muestras.length;

      var puntosEnRect = 0;
      for (final trazo in trazos) {
        for (final p in trazo) {
          if (tight.any((r) => r.contains(p))) puntosEnRect++;
        }
      }

      final ok = ratioMuestra >= 0.42 &&
          puntosEnRect >= minPuntosPorLetra;
      if (!ok) return false;
    }
    return true;
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
      final cajas = painter.getBoxesForSelection(
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
        r.left + r.width * 0.2,
        r.top + r.height * 0.2,
        r.right - r.width * 0.2,
        r.bottom - r.height * 0.2,
      );
      if (inset.width > 1 && inset.height > 1) {
        muestras.addAll([
          inset.topLeft,
          inset.topRight,
          inset.bottomLeft,
          inset.bottomRight,
          Offset(inset.center.dx, inset.top),
          Offset(inset.center.dx, inset.bottom),
        ]);
      }
    }
    return muestras;
  }

  static bool _solapamientoMinimo(Rect trazo, Rect texto) {
    final inter = trazo.intersect(texto);
    if (inter.isEmpty) return false;
    final areaTexto = math.max(_area(texto), 1.0);
    return _area(inter) / areaTexto >= 0.35;
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

  static double _longitudPolilineas(List<List<Offset>> trazos) {
    var total = 0.0;
    for (final trazo in trazos) {
      for (var i = 1; i < trazo.length; i++) {
        total += (trazo[i] - trazo[i - 1]).distance;
      }
    }
    return total;
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
