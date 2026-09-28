/**
 * Binary STL parser — StereoLithography Interface / fabbers.com format:
 *   [80 bytes header]
 *   [uint32 LE triangle count]
 *   repeated:
 *     [3×float32 normal][3×float32 v1][3×float32 v2][3×float32 v3][uint16 attr]
 */
export function parseBinarySTL(buffer) {
  const bytes = buffer instanceof ArrayBuffer ? new Uint8Array(buffer) : new Uint8Array(buffer.buffer);
  if (bytes.byteLength < 84) {
    throw new Error("STL too small for binary header + count");
  }

  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const header = new TextDecoder("latin1").decode(bytes.subarray(0, 80)).replace(/\0+$/, "").trim();
  const triangleCount = view.getUint32(80, true);
  const expected = 84 + triangleCount * 50;
  if (bytes.byteLength < expected) {
    throw new Error(`STL truncated: need ${expected} bytes, got ${bytes.byteLength}`);
  }

  const positions = new Float32Array(triangleCount * 9);
  const normals = new Float32Array(triangleCount * 9);

  let offset = 84;
  let p = 0;
  for (let i = 0; i < triangleCount; i++) {
    const nx = view.getFloat32(offset, true);
    const ny = view.getFloat32(offset + 4, true);
    const nz = view.getFloat32(offset + 8, true);
    offset += 12;

    for (let v = 0; v < 3; v++) {
      const x = view.getFloat32(offset, true);
      const y = view.getFloat32(offset + 4, true);
      const z = view.getFloat32(offset + 8, true);
      offset += 12;
      positions[p] = x;
      positions[p + 1] = y;
      positions[p + 2] = z;
      normals[p] = nx;
      normals[p + 1] = ny;
      normals[p + 2] = nz;
      p += 3;
    }

    offset += 2; // attribute byte count (usually 0)
  }

  return { header, triangleCount, positions, normals };
}
