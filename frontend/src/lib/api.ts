const apiBaseUrl = (
  process.env.NEXT_PUBLIC_RAILS_API_URL ?? "http://127.0.0.1:3000"
).replace(/\/$/, "");

type ApiErrorResponse = {
  error?: string;
  errors?: string[];
};

export async function apiRequest<T>(path: string, options?: RequestInit): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`, options);
  const body = await response.json().catch(() => null) as ApiErrorResponse | null;

  if (!response.ok) {
    throw new Error(
      body?.error ?? body?.errors?.join(", ") ?? `Request failed (${response.status})`,
    );
  }

  return body as T;
}
