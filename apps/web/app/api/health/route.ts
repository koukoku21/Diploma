export async function GET() {
  return Response.json({
    ok: true,
    apiUrl: process.env.API_URL ?? 'NOT_SET',
    env: process.env.NODE_ENV,
  });
}
