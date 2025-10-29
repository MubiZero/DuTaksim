-- Add sessions and collaboration tables

-- Bill Sessions for collaborative bill creation
CREATE TABLE IF NOT EXISTS bill_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    creator_id UUID NOT NULL REFERENCES users(id),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    radius INTEGER DEFAULT 50, -- meters
    status VARCHAR(20) DEFAULT 'active', -- active, closed, finalized
    bill_id UUID REFERENCES bills(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP + INTERVAL '6 hours'
);

-- Session participants (who joined the session)
CREATE TABLE IF NOT EXISTS session_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES bill_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    role VARCHAR(20) DEFAULT 'participant', -- creator, participant
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(session_id, user_id)
);

-- Temporary items added during collaborative session
CREATE TABLE IF NOT EXISTS session_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES bill_sessions(id) ON DELETE CASCADE,
    added_by UUID NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    for_user_id UUID REFERENCES users(id), -- if item is for specific person
    is_shared BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Contact invitations
CREATE TABLE IF NOT EXISTS contact_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inviter_id UUID NOT NULL REFERENCES users(id),
    phone VARCHAR(20) NOT NULL,
    session_id UUID REFERENCES bill_sessions(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, expired
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP + INTERVAL '24 hours'
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_bill_sessions_status ON bill_sessions(status);
CREATE INDEX IF NOT EXISTS idx_bill_sessions_location ON bill_sessions(latitude, longitude) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_bill_sessions_expires ON bill_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_session_participants_session_id ON session_participants(session_id);
CREATE INDEX IF NOT EXISTS idx_session_participants_user_id ON session_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_session_items_session_id ON session_items(session_id);
CREATE INDEX IF NOT EXISTS idx_contact_invitations_phone ON contact_invitations(phone);
CREATE INDEX IF NOT EXISTS idx_contact_invitations_session ON contact_invitations(session_id);
