describe('supabaseAdmin', () => {
  it('throws if env vars are missing', () => {
    const originalUrl = process.env.SUPABASE_URL
    delete process.env.SUPABASE_URL
    jest.resetModules()
    expect(() => require('../supabase-admin')).toThrow('Missing Supabase env vars')
    process.env.SUPABASE_URL = originalUrl
  })
})
