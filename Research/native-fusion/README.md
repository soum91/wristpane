# Native Flow × Siri Modular research

Target: Apple Watch Series 10, watchOS 27.2. Desired result: a real system-selected face with Siri Modular's information layout and Flow's animated glass background and numeral design. The SwiftUI face shipped by WristPane remains independent of this research.

## Evidence reviewed (2026-11-23)

- [HermesEnabler2 watch face research](https://github.com/pookjw/HermesEnabler/blob/main/Research/WatchFaces/README.md): changes device brand/classification so existing Apple face bundles pass eligibility checks. This does not register a new renderer. Its own notes caution that device classification can affect layout and other faces.
- [Physical Series 10 observation](https://github.com/pookjw/HermesEnabler/issues/49): existing Hermès faces appeared on watchOS 27.2.1, then appeared on the companion after a full restart. This is not a custom-face registration experiment.
- [Clocky NanoTimeKit research](https://github.com/pookjw/Clocky/blob/main/Research/NanoTimeKit.md): the native face models, bundle manager, descriptor and view-controller architecture are distinct from the application that presents them. Native face rendering inside a third-party process does not prove registration with the system face host.
- [Clocky Always On research](https://github.com/pookjw/Clocky/blob/main/Research/AlwaysOn.md): even its use of Apple renderers did not establish 1 Hz AOD refresh inside an app.
- [NTKCustomFace](https://github.com/justMaku/NTKCustomFace): historical simulator-only custom face demonstration; the author explicitly rules out actual hardware support.
- [CustomWatchFaceTest](https://github.com/hamzasood/CustomWatchFaceTest): historical experiment requires custom code to be loaded into the system face host. No verified current hardware path.
- [Apple watch-face import API](https://developer.apple.com/documentation/clockkit/clkwatchfacelibrary/addwatchface(at:completionhandler:)): imports a watch-face configuration, not an arbitrary rendering implementation.

## Next falsifiable test

Use the native Watch app's sharing UI to export a genuine Flow face and a genuine Siri Modular face. Also export a second version of each with a changed color or complication if available. Save the original files privately. Do not export personal complications that contain sensitive data.

Run the companion offline inspector:

`python3 Research/native-fusion/inspect_faces.py Flow.watchface SiriModular.watchface`

It reads only ZIP metadata and recognized serialized configuration structures. It reports paths, types and field names, not configuration values or embedded images. No extraction, writes, network calls, device modification or installation. Keep raw archives private. Compare face-specific structural fields and whether renderer-specific appearance settings actually coexist with modular complication fields. A structural match is a hypothesis, not a proof that the native importer honors those settings.

## Decision gates

1. Establish the actual face IDs and configuration schema using the two native exports (local inspection).
2. Determine whether the native file format can express a mix of the two renderers. Do not assume a shared key implies shared semantics.
3. If the format is insufficient, document the gap: custom native renderer registration remains a separate system capability not demonstrated by the reviewed physical-device projects.
4. Any future native test must be reversible and preserve the currently working watch configuration. Do not change device branding, screen class, or MobileGestalt merely to test a hybrid renderer: these are unrelated to adding a custom face.
5. Success means the face appears in the system gallery, can be selected, survives return to clock and restart, supports real complications, and is evaluated on physical hardware including AOD. An app screenshot or a successful compile is not success.

Current status: research only. No native face has been installed or registered. No firmware, MobileGestalt, or system process changes have been made. Do not advertise native face installation in a WristPane release until demonstrated.
