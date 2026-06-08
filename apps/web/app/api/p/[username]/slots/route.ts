import { NextRequest, NextResponse } from 'next/server';

const API = process.env.API_URL ?? 'http://localhost:3001';

export async function GET(req: NextRequest, { params }: { params: { username: string } }) {
  const { searchParams } = req.nextUrl;
  const res = await fetch(
    `${API}/p/${params.username}/slots?${searchParams.toString()}`,
    { cache: 'no-store' },
  );
  const data = await res.json();
  return NextResponse.json(data, { status: res.status });
}
