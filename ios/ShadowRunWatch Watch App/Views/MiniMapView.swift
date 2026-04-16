import SwiftUI
import MapKit

struct MiniMapView: View {
    let runnerLat: Double
    let runnerLon: Double
    let shadowLat: Double?
    let shadowLon: Double?
    let showShadow: Bool

    var runnerCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: runnerLat, longitude: runnerLon)
    }

    var body: some View {
        Map {
            Annotation("", coordinate: runnerCoord) {
                Circle()
                    .fill(.green)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(.green.opacity(0.4), lineWidth: 2)
                            .frame(width: 18, height: 18)
                    )
            }

            if showShadow, let sLat = shadowLat, let sLon = shadowLon,
               sLat != 0, sLon != 0 {
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: sLat, longitude: sLon
                )) {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(.red.opacity(0.4), lineWidth: 2)
                                .frame(width: 18, height: 18)
                        )
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .allowsHitTesting(false)
    }
}
