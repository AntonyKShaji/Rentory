CREATE TABLE users (
  id UUID PRIMARY KEY,
  role VARCHAR(20) NOT NULL CHECK (role IN ('owner', 'tenant', 'supervisor')),
  full_name VARCHAR(120) NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(120),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE owner_bank_accounts (
  id UUID PRIMARY KEY,
  owner_id UUID NOT NULL REFERENCES users(id),
  account_holder_name VARCHAR(120) NOT NULL,
  account_number VARCHAR(50) NOT NULL,
  ifsc_code VARCHAR(20),
  upi_id VARCHAR(100)
);

CREATE TABLE properties (
  id UUID PRIMARY KEY,
  owner_id UUID NOT NULL REFERENCES users(id),
  location VARCHAR(120) NOT NULL,
  property_name VARCHAR(120) NOT NULL,
  unit_type VARCHAR(20) NOT NULL,
  total_capacity INT NOT NULL,
  occupied_count INT NOT NULL DEFAULT 0,
  broker_name VARCHAR(120),
  broker_phone VARCHAR(20),
  lease_valid_till DATE
);

CREATE TABLE property_tenants (
  id UUID PRIMARY KEY,
  property_id UUID NOT NULL REFERENCES properties(id),
  tenant_id UUID NOT NULL REFERENCES users(id),
  joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
  status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'active', 'rejected'))
);

CREATE TABLE bills (
  id UUID PRIMARY KEY,
  property_id UUID NOT NULL REFERENCES properties(id),
  tenant_id UUID REFERENCES users(id),
  bill_type VARCHAR(20) NOT NULL CHECK (bill_type IN ('rent', 'electricity', 'water')),
  amount NUMERIC(12, 2) NOT NULL,
  due_date DATE NOT NULL,
  status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'paid', 'overdue')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
  id UUID PRIMARY KEY,
  bill_id UUID REFERENCES bills(id),
  paid_by UUID NOT NULL REFERENCES users(id),
  amount NUMERIC(12, 2) NOT NULL,
  payment_method VARCHAR(40),
  transaction_ref VARCHAR(120),
  paid_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  sender_user_id UUID NOT NULL REFERENCES users(id),
  receiver_user_id UUID REFERENCES users(id),
  property_id UUID REFERENCES properties(id),
  title VARCHAR(160) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(30) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE maintenance_tickets (
  id UUID PRIMARY KEY,
  property_id UUID NOT NULL REFERENCES properties(id),
  tenant_id UUID NOT NULL REFERENCES users(id),
  issue_title VARCHAR(160) NOT NULL,
  issue_description TEXT,
  assigned_to VARCHAR(120),
  assigned_phone VARCHAR(20),
  status VARCHAR(20) NOT NULL CHECK (status IN ('open', 'assigned', 'closed')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
