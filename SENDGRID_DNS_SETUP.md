# SendGrid DNS Configuration for galadevs.com

## Your DNS Records to Add

Add these 4 records to your DNS provider for **galadevs.com**:

### 1. CNAME Record
```
Type:  CNAME
Host:  em1011
Value: u58550987.wl238.sendgrid.net
```

### 2. CNAME Record (Domain Key 1)
```
Type:  CNAME
Host:  s1._domainkey
Value: s1.domainkey.u58550987.wl238.sendgrid.net
```

### 3. CNAME Record (Domain Key 2)
```
Type:  CNAME
Host:  s2._domainkey
Value: s2.domainkey.u58550987.wl238.sendgrid.net
```

### 4. TXT Record (DMARC)
```
Type:  TXT
Host:  _dmarc
Value: v=DMARC1; p=none
```

---

## How to Add DNS Records

### Option 1: Cloudflare (Most Common)

1. Login to Cloudflare: https://dash.cloudflare.com/
2. Click your domain: **galadevs.com**
3. Go to **DNS** → **Records**
4. Click **Add record**
5. Add each record:
   - **Type**: Select CNAME or TXT
   - **Name**: Enter host (e.g., `em1011` or `s1._domainkey`)
   - **Target/Content**: Enter value
   - **Proxy status**: Turn OFF (DNS only - gray cloud)
   - **TTL**: Auto or 3600
   - Click **Save**
6. Repeat for all 4 records

### Option 2: GoDaddy

1. Login to GoDaddy: https://dcc.godaddy.com/
2. Go to **My Products** → **DNS** for galadevs.com
3. Click **Add** button
4. For CNAME records:
   - **Type**: CNAME
   - **Name**: Enter host (e.g., `em1011`)
   - **Value**: Enter target
   - **TTL**: 600 seconds
   - Click **Save**
5. For TXT record:
   - **Type**: TXT
   - **Name**: `_dmarc`
   - **Value**: `v=DMARC1; p=none`
   - Click **Save**

### Option 3: Namecheap

1. Login to Namecheap: https://ap.www.namecheap.com/
2. Domain List → Click **Manage** for galadevs.com
3. Go to **Advanced DNS** tab
4. Click **Add New Record**
5. Add each record with same settings as above

### Option 4: Other DNS Providers

Look for:
- "DNS Management"
- "DNS Records"
- "Advanced DNS"
- "Manage DNS"

Then add the 4 records with Type, Host, and Value as shown above.

---

## Important Notes

### Host/Name Field
Some DNS providers want just the subdomain:
- ✅ Use: `em1011` (not `em1011.galadevs.com`)
- ✅ Use: `s1._domainkey` (not `s1._domainkey.galadevs.com`)
- ✅ Use: `_dmarc` (not `_dmarc.galadevs.com`)

If your provider shows the full domain in preview, that's fine - they'll append it automatically.

### Proxy Status (Cloudflare)
For CNAME records, turn OFF proxy (gray cloud icon). DNS-only mode required for email verification.

### TTL (Time To Live)
- Default: 3600 seconds (1 hour)
- Quick propagation: 600 seconds (10 minutes)
- After verification: Can increase to 86400 (24 hours)

---

## Verify DNS Records

### Check if DNS is propagated (5-30 minutes)

```bash
# Check CNAME records
dig em1011.galadevs.com CNAME
dig s1._domainkey.galadevs.com CNAME
dig s2._domainkey.galadevs.com CNAME

# Check TXT record
dig _dmarc.galadevs.com TXT
```

Or use online tool: https://mxtoolbox.com/SuperTool.aspx

### Verify in SendGrid

1. Go to SendGrid Dashboard
2. **Settings** → **Sender Authentication**
3. Find your domain verification
4. Click **Verify** button
5. Should show ✅ green checkmarks

---

## Configure Supabase with Verified Domain

Once DNS is verified in SendGrid:

1. Go to Supabase: https://supabase.com/dashboard/project/tpejvjznleoinsanrgut
2. **Authentication** → **SMTP Settings**
3. Enable **Custom SMTP**
4. Configure:
   ```
   Host: smtp.sendgrid.net
   Port: 587
   Username: apikey
   Password: [YOUR_SENDGRID_API_KEY]
   Sender email: noreply@galadevs.com  ← Use your verified domain!
   Sender name: Coffeenance
   ```
5. Click **Save**

### Add Redirect URLs
1. Still in Authentication settings
2. **URL Configuration** → **Redirect URLs**
3. Add:
   ```
   coffeenance://verify-email
   coffeenance://**
   http://localhost:3000/**
   ```
4. **Site URL**: `coffeenance://`
5. Click **Save**

---

## Test Email Verification

After DNS is verified and Supabase is configured:

```bash
./run_debug.sh
```

1. Register with real email (any domain)
2. Check inbox for verification email from **noreply@galadevs.com**
3. Click verification link
4. App should open automatically
5. User verified and logged in! ✅

---

## Troubleshooting

### "DNS not verified"
- Wait 5-30 minutes for DNS propagation
- Check DNS with `dig` command
- Ensure proxy is OFF (Cloudflare)
- Verify exact host names (no typos)

### "Email from wrong domain"
After verification, update Supabase sender email to: `noreply@galadevs.com`

### "Email still not received"
- Check spam folder
- Verify SendGrid API key is correct
- Check SendGrid dashboard for delivery errors
- Verify sender email matches verified domain

---

## Quick Checklist

- [ ] Add 3 CNAME records to DNS
- [ ] Add 1 TXT record to DNS
- [ ] Wait 5-30 minutes for propagation
- [ ] Verify in SendGrid dashboard (green ✅)
- [ ] Configure SMTP in Supabase
- [ ] Set sender email: noreply@galadevs.com
- [ ] Add redirect URLs in Supabase
- [ ] Test with `./run_debug.sh`
- [ ] Register and check email
- [ ] Click link → App opens → Success! 🎉

---

## Your DNS Records Summary

```
CNAME  em1011              → u58550987.wl238.sendgrid.net
CNAME  s1._domainkey       → s1.domainkey.u58550987.wl238.sendgrid.net
CNAME  s2._domainkey       → s2.domainkey.u58550987.wl238.sendgrid.net
TXT    _dmarc              → v=DMARC1; p=none
```

Add these to your DNS provider for **galadevs.com** and you're set! 🚀
