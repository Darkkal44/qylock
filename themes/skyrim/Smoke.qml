pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Particles
import Qt5Compat.GraphicalEffects

// Skyrim main-menu fog, rebuilt with QtQuick.Particles using the game's smoke
// flipbook (assets/smoke.png, 8x8 frames). Many large, very faint puffs rise
// from below the bottom edge and overlap into one soft mass.
//
// The screen is split into vertical strips, each with its own emitter. A strip's
// rise speed is set so a puff's top edge reaches that strip's ceiling as the puff
// dies (ImageParticle.Fade fades it out over its last quarter of life). The
// ceiling slopes from ceilLeft on the left down to ceilRight on the right.
// Two depth layers: a far one (bigger, fainter, slower) behind the near one.
// The bottom edge, where every puff overlaps at birth, is dimmed by a mask.
Item {
    id: smoke

    // Near layer
    property real puffAlpha: 0.035       // per-particle opacity
    property real emitRate: 6            // particles per second, all strips together
    property real lifeSeconds: 8         // puff lifetime (game: 8.3s +/- 3.3s)
    property real lifeJitter: 0.3        // +/- lifetime fraction; uneven top edge of the mist
    property real puffSize: 0.5          // birth size, fraction of screen width
    property real growth: 1.8            // end size / birth size

    // Far layer, as multipliers of the near layer
    property real farSize: 1.3
    property real farAlpha: 0.02         // absolute opacity, not a multiplier
    property real farRate: 0.4
    property real farLife: 1.3

    // Shape and look
    property real ceilLeft: 0.6          // max height on the left, fraction of screen height
    property real ceilRight: 0.4         // max height on the right, fraction of screen height
    property real drift: 0.02            // max sideways speed, fraction of screen width per second
    property int strips: 8               // number of emitter strips across the width
    property color tint: "#8f877d"       // warm gray
    property real bottomAlpha: 0.3       // opacity multiplier at the very bottom edge
    property real bottomFade: 0.35       // height over which it eases up to full, fraction of screen height

    // A puff's visible top edge sits about this far above its center, as a
    // fraction of sprite size (the smoke doesn't fill the whole frame).
    readonly property real topReach: 0.35

    // Ceiling height in px at horizontal position u (0 = left, 1 = right)
    function ceilingAt(u) {
        return height * (ceilLeft + (ceilRight - ceilLeft) * u);
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: bottomMask
        }

        ParticleSystem {
            id: sys
        }

        // Far layer first so it renders behind the near one
        ImageParticle {
            system: sys
            groups: ["far"]
            color: smoke.tint
            alpha: smoke.farAlpha
            entryEffect: ImageParticle.Fade
            rotationVariation: 180
            rotationVelocityVariation: 5
            sprites: Sprite {
                source: "assets/smoke.png"
                frameCount: 64
                frameWidth: 256
                frameHeight: 256
                frameRate: 7
                frameRateVariation: 1.5
                randomStart: true
            }
        }
        ImageParticle {
            system: sys
            groups: ["near"]
            color: smoke.tint
            alpha: smoke.puffAlpha
            entryEffect: ImageParticle.Fade
            rotationVariation: 180
            rotationVelocityVariation: 8
            sprites: Sprite {
                source: "assets/smoke.png"
                frameCount: 64
                frameWidth: 256
                frameHeight: 256
                frameRate: 10
                frameRateVariation: 2   // game runs ~12.6
                randomStart: true
            }
        }

        // One set of strip emitters per depth layer
        Repeater {
            model: [
                {
                    group: "far",
                    size: smoke.farSize,
                    rate: smoke.farRate,
                    life: smoke.farLife
                },
                {
                    group: "near",
                    size: 1,
                    rate: 1,
                    life: 1
                }
            ]
            delegate: Item {
                id: depthLayer
                required property var modelData
                readonly property real size0: smoke.width * smoke.puffSize * modelData.size
                readonly property real size1: size0 * smoke.growth
                readonly property real life: smoke.lifeSeconds * modelData.life

                Repeater {
                    model: smoke.strips
                    delegate: Emitter {
                        id: emitter
                        required property int index
                        readonly property real ceiling: smoke.ceilingAt((index + 0.5) / smoke.strips)
                        // The top edge starts at the bottom of the screen and must end at the ceiling
                        readonly property real travel: Math.max(0, ceiling - smoke.topReach * (depthLayer.size1 - depthLayer.size0))

                        system: sys
                        group: depthLayer.modelData.group
                        x: smoke.width * index / smoke.strips
                        y: smoke.height + smoke.topReach * depthLayer.size0
                        width: smoke.width / smoke.strips
                        height: smoke.topReach * depthLayer.size0      // staggered births below the screen
                        shape: RectangleShape {}
                        // Taller strips (left) get proportionally more puffs
                        emitRate: smoke.emitRate * depthLayer.modelData.rate * ceiling / (smoke.height * (smoke.ceilLeft + smoke.ceilRight) / 2) / smoke.strips
                        lifeSpan: depthLayer.life * 1000
                        lifeSpanVariation: depthLayer.life * 1000 * smoke.lifeJitter
                        size: depthLayer.size0
                        sizeVariation: depthLayer.size0 * 0.2
                        endSize: depthLayer.size1
                        velocity: AngleDirection {
                            angle: 270
                            angleVariation: 4
                            magnitude: emitter.travel / depthLayer.life
                            magnitudeVariation: emitter.travel * 0.1 / depthLayer.life
                        }
                    }
                }
            }
        }

        // Slow random sideways drift so puffs don't rise in straight columns.
        // Horizontal only, so it never pushes puffs past their ceiling.
        Wander {
            system: sys
            affectedParameter: Wander.Velocity
            xVariance: smoke.width * smoke.drift
            yVariance: 0
            pace: smoke.width * smoke.drift
        }
    }

    // Full opacity above bottomFade, easing down to bottomAlpha at the bottom edge
    Rectangle {
        id: bottomMask
        anchors.fill: parent
        visible: false
        gradient: Gradient {
            GradientStop {
                position: 1 - smoke.bottomFade
                color: "white"
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(1, 1, 1, smoke.bottomAlpha)
            }
        }
    }
}
