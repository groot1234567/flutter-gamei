import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame with PanDetector {
  CircleComponent? ball;
  int ammo = 20; // 🔥 Başlangıç mermisi 20'ye çıkarıldı
  int level = 1;
  bool gameOver = false;
  bool win = false;
  bool _isInitialized = false;

  Vector2 velocity = Vector2.zero();
  Vector2? dragStart;
  Vector2? dragCurrent;
  List<RectangleComponent> blocks = [];

  void createLevel() {
    if (size.x <= 0) return;

    for (var b in blocks) { b.removeFromParent(); }
    blocks.clear();

    double bWidth = 64;
    double bHeight = 32;
    double gap = 8;
    int count = level + 2;

    double totalW = (count * bWidth) + ((count - 1) * gap);
    double startX = (size.x - totalW) / 2;

    for (int i = 0; i < count; i++) {
      for (int j = 0; j < level; j++) {
        final block = RectangleComponent(
          size: Vector2(bWidth, bHeight),
          position: Vector2(startX + i * (bWidth + gap), 100 + j * (bHeight + gap)),
          paint: Paint()..color = Colors.greenAccent,
        );
        blocks.add(block);
        add(block);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    ball = CircleComponent(
      radius: 12,
      anchor: Anchor.center,
      paint: Paint()..color = Colors.redAccent,
      position: Vector2(size.x / 2, size.y * 0.8), // İlk yüklemede güvenli konum
    );
    add(ball!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0) {
      // Her açılışta ve boyut değişiminde topu merkeze zorla
      if (!_isInitialized) {
        ball?.position = Vector2(size.x / 2, size.y * 0.8);
        createLevel();
        _isInitialized = true;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (ball == null || !_isInitialized) return;

    ball!.position += velocity;

    if (ball!.position.x < 12 || ball!.position.x > size.x - 12) velocity.x *= -1;
    if (ball!.position.y < 12 || ball!.position.y > size.y - 12) velocity.y *= -1;

    velocity *= 0.98;

    blocks.removeWhere((block) {
      if (ball!.position.distanceTo(block.position + block.size / 2) < 35) {
        velocity.y *= -1;
        block.removeFromParent();
        return true;
      }
      return false;
    });

    if (ammo <= 0 && velocity.length < 0.5 && blocks.isNotEmpty && !gameOver) {
      gameOver = true;
      win = false;
    }

    if (blocks.isEmpty && !gameOver && _isInitialized) {
      gameOver = true;
      win = true;
    }
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (gameOver) {
      resetGame();
    } else {
      dragStart = info.eventPosition.global;
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    dragCurrent = info.eventPosition.global;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (ammo > 0 && !gameOver && dragStart != null && dragCurrent != null) {
      final diff = dragStart! - dragCurrent!;
      velocity = diff * 0.06;
      ammo--;
    }
    dragStart = null;
    dragCurrent = null;
  }

  void resetGame() {
    if (win) {
      level++;
      ammo += 10; // Her seviye atladığında +10 mermi bonusu (Opsiyonel)
    } else {
      ammo = 20; // Kaybedince 20'ye sıfırla
    }

    ball?.position = Vector2(size.x / 2, size.y * 0.8);
    velocity = Vector2.zero();
    gameOver = false;
    win = false;
    createLevel();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_isInitialized) return;

    if (dragStart != null && dragCurrent != null) {
      canvas.drawLine(
          dragStart!.toOffset(),
          dragCurrent!.toOffset(),
          Paint()..color = Colors.blue.withOpacity(0.5)..strokeWidth = 3
      );
    }

    _drawText(canvas, 'Mermi: $ammo', const Offset(20, 50));
    _drawText(canvas, 'Level: $level', const Offset(20, 80));

    if (gameOver) {
      String mainMsg = win ? 'TEBRİKLER! KAZANDIN' : 'OYUN BİTTİ! KAYBETTİN';
      Color msgColor = win ? Colors.yellowAccent : Colors.redAccent;

      _drawText(canvas, mainMsg, Offset(size.x / 2 - 140, size.y / 2), color: msgColor, fontSize: 28);
      _drawText(canvas, 'DEVAM ETMEK İÇİN TIKLA', Offset(size.x / 2 - 110, size.y / 2 + 50), fontSize: 16);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, {Color color = Colors.white, double fontSize = 22}) {
    TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)
      ),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, offset);
  }
}