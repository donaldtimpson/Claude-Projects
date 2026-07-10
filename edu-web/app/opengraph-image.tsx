import { ImageResponse } from "next/og";

// Default social share card for the whole site (Facebook, iMessage, Slack, etc.).
// Per-course pages override this via their own generateMetadata.
export const alt = "The Timpson Lyceum — a classical education in mathematics, logic, and philosophy.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpenGraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          height: "100%",
          width: "100%",
          display: "flex",
          backgroundColor: "#0f0404",
          padding: 48,
        }}
      >
        <div
          style={{
            flex: 1,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            border: "3px solid #b8860b",
            borderRadius: 20,
            backgroundColor: "#190808",
          }}
        >
          <div
            style={{
              width: 22,
              height: 22,
              backgroundColor: "#cfa135",
              transform: "rotate(45deg)",
              marginBottom: 28,
            }}
          />
          <div
            style={{
              fontSize: 86,
              fontWeight: 700,
              color: "#ddb954",
              letterSpacing: 4,
              textAlign: "center",
              lineHeight: 1.1,
            }}
          >
            The Timpson Lyceum
          </div>
          <div
            style={{
              width: 220,
              height: 2,
              backgroundColor: "#9a7209",
              margin: "28px 0",
            }}
          />
          <div
            style={{
              fontSize: 30,
              color: "#c4af8e",
              textAlign: "center",
              maxWidth: 760,
              lineHeight: 1.3,
            }}
          >
            A classical education in mathematics, logic, and philosophy.
          </div>
        </div>
      </div>
    ),
    { ...size },
  );
}
