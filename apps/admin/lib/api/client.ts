import axios from "axios";

const apiBaseUrl =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:4040/api/v1";

export const api = axios.create({
  baseURL: apiBaseUrl,
  timeout: 10000,
  headers: {
    "Content-Type": "application/json",
  },
});

export function setAuthToken(token: string | null) {
  if (token) {
    api.defaults.headers.common.Authorization = `Bearer ${token}`;
  } else {
    delete api.defaults.headers.common.Authorization;
  }
}