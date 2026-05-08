describe('supabaseAdmin', () => {
  it('throws if env vars are missing', async () => {
    const originalUrl = process.env.SUPABASE_URL
    delete process.env.SUPABASE_URL
    jest.resetModules()
    await expect(import('../supabase-admin')).rejects.toThrow('Missing Supabase env vars')
    process.env.SUPABASE_URL = originalUrl
  })
})
