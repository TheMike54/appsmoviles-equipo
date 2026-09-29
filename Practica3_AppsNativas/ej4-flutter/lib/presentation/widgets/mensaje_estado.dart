import 'package:flutter/material.dart';

/// Aviso a pantalla completa reutilizable: ícono, explicación y acciones.
/// Se usa cuando no hay cámara o micrófono, o cuando el usuario negó un
/// permiso, para que la app siempre diga qué pasó en vez de quedarse trabada.
class MensajeEstado extends StatelessWidget {
  const MensajeEstado({
    super.key,
    required this.icono,
    required this.mensaje,
    this.acciones = const [],
  });

  final IconData icono;
  final String mensaje;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 72),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (acciones.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: acciones,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
