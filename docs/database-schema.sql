-- Rentory v1.1 relational schema

CREATE TABLE users (
  id UUID PRIMARY KEY,
  role VARCHAR(20) NOT NULL CHECK (role IN ('owner', 'tenant')),
  full_name VARCHAR(120) NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(120),
  password_hash VARCHAR(120) NOT NULL,
  age INT,
  documents TEXT,
  assigned_property_id UUID,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE properties (
  id UUID PRIMARY KEY,
  owner_id UUID NOT NULL REFERENCES users(id),
  location VARCHAR(120) NOT NULL,
  name VARCHAR(120) NOT NULL,
  unit_type VARCHAR(40) NOT NULL,
  description TEXT,
  image_url TEXT NOT NULL,
  qr_code VARCHAR(64) UNIQUE NOT NULL,
  capacity INT NOT NULL,
  occupied_count INT NOT NULL DEFAULT 0,
  rent NUMERIC(12, 2) NOT NULL,
  current_bill_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
  water_bill_status VARCHAR(20) NOT NULL CHECK (water_bill_status IN ('paid', 'unpaid'))
);

ALTER TABLE users
  ADD CONSTRAINT fk_users_assigned_property
  FOREIGN KEY (assigned_property_id) REFERENCES properties(id);

CREATE TABLE property_tenants (
  id UUID PRIMARY KEY,
  property_id UUID NOT NULL REFERENCES properties(id),
  tenant_id UUID NOT NULL REFERENCES users(id),
  status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'active', 'rejected')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_property_tenant UNIQUE (property_id, tenant_id)
);

CREATE TABLE chat_groups (
  id UUID PRIMARY KEY,
  property_id UUID NOT NULL UNIQUE REFERENCES properties(id),
  group_name VARCHAR(160) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE chat_group_members (
  id UUID PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES chat_groups(id),
  user_id UUID NOT NULL REFERENCES users(id),
  role VARCHAR(20) NOT NULL CHECK (role IN ('owner', 'tenant')),
  joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_chat_group_member UNIQUE (group_id, user_id)
);

CREATE TABLE chat_messages (
  id UUID PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES chat_groups(id),
  sender_id UUID NOT NULL REFERENCES users(id),
  sender_name VARCHAR(120) NOT NULL,
  text TEXT,
  image_url TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_message_has_content CHECK (text IS NOT NULL OR image_url IS NOT NULL)
);

CREATE TABLE bills (
  id UUID PRIMARY KEY,
  property_id UUID NOT NULL REFERENCES properties(id),
  tenant_id UUID NOT NULL REFERENCES users(id),
  bill_type VARCHAR(20) NOT NULL CHECK (bill_type IN ('rent', 'electricity', 'water')),
  amount NUMERIC(12, 2) NOT NULL,
  status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'paid', 'overdue')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
  id UUID PRIMARY KEY,
  property_id UUID NOT NULL REFERENCES properties(id),
  tenant_id UUID NOT NULL REFERENCES users(id),
  bill_type VARCHAR(20) NOT NULL CHECK (bill_type IN ('rent', 'electricity', 'water')),
  amount NUMERIC(12, 2) NOT NULL,
  paid_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  owner_id UUID NOT NULL REFERENCES users(id),
  property_id UUID REFERENCES properties(id),
  title VARCHAR(160) NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE maintenance_tickets (
  id UUID PRIMARY KEY,
  property_id UUID NOT NULL REFERENCES properties(id),
  tenant_id UUID NOT NULL REFERENCES users(id),
  issue_title VARCHAR(160) NOT NULL,
  issue_description TEXT,
  status VARCHAR(20) NOT NULL CHECK (status IN ('open', 'closed')),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
