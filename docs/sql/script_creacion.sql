-- ============================================================================
-- ECOMMERCE MULTITENANT - ALEXARA SCHEMA COMPLETO 3NF COMPOSITE-OPTIMIZED
-- ============================================================================
-- 
-- PRINCIPIOS DE ARQUITECTURA:
-- 1. Aislamiento Multitenant Físico Estricto:
--    Las entidades específicas de una tienda (Tenant) incluyen siempre la columna
--    'tenant_id' y utilizan Llaves Primarias y Foráneas Compuestas para asegurar 
--    un particionamiento de datos robusto y evitar fugas de información.
-- 2. Normalización de Tercera Forma Normal (3NF):
--    El diseño evita redundancias complejas y mantiene la integridad referencial.
-- 3. Optimización de Llaves Primarias Naturales Compuestas (Composite-Optimized):
--    Se han eliminado IDs artificiales redundantes (surrogate keys) y sus B-tree
--    índices duplicados en las tablas dependientes (tenant_settings, cart_items, 
--    order_items y order_shipments), mejorando drásticamente el uso de memoria RAM
--    de índices, espacio en disco y el rendimiento de inserciones a escala.
--
-- ============================================================================
-- MAPA DE LA BASE DE DATOS (36 TABLAS EN 5 ÁREAS LÓGICAS)
-- ============================================================================
--
-- AREA 1: CONFIGURACIONES GLOBALES Y CATÁLOGOS (13 Tablas)
--   1. attribute_types ........ Tipos de atributos de producto (select, text, number, boolean)
--   2. product_statuses ...... Estados de visibilidad de producto (draft, active, archived)
--   3. tenant_plans .......... Planes de suscripción SaaS para las tiendas (free, pro, enterprise)
--   4. currencies ............ Monedas globales de la plataforma
--   5. tenant_roles .......... Roles administrativos para las tiendas (owner, admin, etc.)
--   6. audit_actions ......... Acciones globales registradas en auditorías (create, update, delete)
--   7. resource_types ........ Tipos de recursos auditables del sistema
--   8. order_statuses ........ Estados transaccionales de órdenes (pending, confirmed, etc.)
--   9. shipment_statuses ..... Estados del ciclo de envío (processing, shipped, delivered)
--  10. payment_statuses ...... Estados del ciclo del pago (pending, approved, rejected, etc.)
--  11. payment_methods ....... Métodos de pago base nativos (mercado_pago, modo, go_cuotas, etc.)
--  12. countries ............. Países del sistema global
--  13. provinces ............. Provincias o Estados federados vinculados a países
--
-- AREA 2: ENTIDADES CORE GLOBALES (4 Tablas)
--  14. users ................. Usuarios globales registrados en la plataforma SaaS
--  15. user_sessions ......... Sesiones de inicio de sesión de usuario globales
--  16. user_addresses ........ Direcciones de envío del usuario (compartidas y reutilizables)
--  17. user_audit_logs ....... Log de acciones de auditoría global por usuario
--
-- AREA 3: ESTRUCTURA DE TIENDAS / TENANTS (6 Tablas)
--  18. tenants ............... Tiendas registradas en la plataforma SaaS
--  19. tenant_members ........ Administradores y colaboradores de la tienda (N:M con PK Compuesta)
--  20. tenant_settings ....... Ajustes generales de moneda, impuestos y envío de la tienda (1:1 con PK Compuesta)
--  21. tenant_payment_gateways Configuración y credenciales seguras de pasarelas de pago de la tienda
--  22. tenant_email_settings . Configuración del servidor de correo SMTP propio de la tienda
--  23. tenant_invitations .... Invitaciones enviadas para sumar colaboradores a la tienda
--
-- AREA 4: CLIENTES Y CATÁLOGO POR TIENDA (6 Tablas)
--  24. customers ............. Relación comprador-tienda y registro de clientes de cada tenant
--  25. categories ............ Categorías de productos aisladas físicamente por tienda
--  26. attribute_templates ... Plantillas de atributos específicos para cada tienda
--  27. attribute_options ..... Valores de atributos disponibles para las variantes de producto
--  28. products .............. Catálogo de productos específicos de cada tienda
--  29. product_variants ...... Variantes de stock específicas de producto por tienda
--
-- AREA 5: CARRITOS, VENTAS Y TRANSACCIONES (7 Tablas)
--  30. product_images ........ Imágenes de productos y variantes específicas por tienda
--  31. carts ................. Carritos de compras de clientes logueados o invitados por tienda
--  32. cart_items ............ Variantes agregadas al carrito (PK Compuesta natural ultra-optimizada)
--  33. orders ................ Órdenes de compra con cálculo de stock temporal de Soft Allocation
--  34. order_items ........... Líneas de detalle físicas de la orden (PK Compuesta natural ultra-optimizada)
--  35. order_shipments ....... Envío y snapshot de la dirección de la orden (PK Compuesta natural 1:1)
--  36. payments .............. Transacciones y cobros asociados a las órdenes por tienda
--
-- ============================================================================


-- ============================================================================
-- TABLAS DE REFERENCIA GLOBALES (Lookup tables)
-- ============================================================================

CREATE TABLE attribute_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "select", "text", "number", "boolean"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO attribute_types (name, description) VALUES
    ('select',  'Lista de opciones predefinidas'),
    ('text',    'Texto libre'),
    ('number',  'Valor numérico'),
    ('boolean', 'Verdadero / Falso')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE product_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "draft", "active", "archived"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO product_statuses (name, description) VALUES
    ('draft',    'Borrador - no visible en tienda'),
    ('active',   'Activo - visible en tienda'),
    ('archived', 'Archivado - no visible en tienda')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE tenant_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "free", "pro", "enterprise"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO tenant_plans (name, description) VALUES
    ('free',       'Plan gratuito con funcionalidades básicas'),
    ('pro',        'Plan profesional con funcionalidades avanzadas'),
    ('enterprise', 'Plan enterprise con soporte dedicado')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE currencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,  -- "ARS", "USD", "EUR"
    name TEXT NOT NULL,
    symbol TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO currencies (code, name, symbol) VALUES
    ('ARS', 'Peso Argentino',  '$'),
    ('USD', 'Dólar Estadounidense', 'US$'),
    ('EUR', 'Euro', '€')
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE tenant_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "owner", "editor", "viewer"
    description TEXT,
    permissions JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO tenant_roles (name, description, permissions) VALUES
    ('owner',  'Propietario de la tienda - Acceso total',
     '{"can_edit_products":true,"can_edit_settings":true,"can_view_analytics":true,"can_manage_team":true,"can_delete_store":true}'),
    ('editor', 'Editor - Puede editar productos y órdenes',
     '{"can_edit_products":true,"can_edit_settings":false,"can_view_analytics":true,"can_manage_team":false,"can_delete_store":false}'),
    ('viewer', 'Visualizador - Solo lectura',
     '{"can_edit_products":false,"can_edit_settings":false,"can_view_analytics":true,"can_manage_team":false,"can_delete_store":false}')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE audit_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "login", "logout", "update_profile", "invite_user"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO audit_actions (name, description) VALUES
    ('login',          'Inicio de sesión'),
    ('logout',         'Cierre de sesión'),
    ('update_profile', 'Actualización de perfil'),
    ('invite_user',    'Invitación de usuario'),
    ('create_product', 'Creación de producto'),
    ('update_product', 'Actualización de producto'),
    ('delete_product', 'Eliminación de producto')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE resource_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "product", "order", "settings"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO resource_types (name, description) VALUES
    ('product',  'Producto del catálogo'),
    ('order',    'Orden de compra'),
    ('settings', 'Configuración de tienda'),
    ('user',     'Usuario del sistema')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE order_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "pending", "confirmed", "processing", "shipped", "delivered", "cancelled"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO order_statuses (name, description) VALUES
    ('pending', 'Pendiente de confirmación'),
    ('confirmed', 'Confirmada'),
    ('processing', 'En preparación'),
    ('shipped', 'Enviada'),
    ('delivered', 'Entregada'),
    ('cancelled', 'Cancelada')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE shipment_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "pending", "shipped", "in_transit", "delivered", "returned"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO shipment_statuses (name, description) VALUES
    ('pending', 'Pendiente'),
    ('shipped', 'Enviada'),
    ('in_transit', 'En tránsito'),
    ('delivered', 'Entregada'),
    ('returned', 'Devuelta')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE payment_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "pending", "approved", "rejected", "refunded"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO payment_statuses (name, description) VALUES
    ('pending', 'Pendiente'),
    ('approved', 'Aprobado'),
    ('rejected', 'Rechazado'),
    ('refunded', 'Reembolsado')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,  -- "mercado_pago", "credit_card", "bank_transfer", "cash"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO payment_methods (name, description) VALUES
    ('mercado_pago', 'Mercado Pago'),
    ('go_cuotas', 'Go Cuotas (Débito)'),
    ('modo', 'MODO (Billetera)'),
    ('credit_card', 'Tarjeta genérica'),
    ('bank_transfer', 'Transferencia bancaria'),
    ('cash', 'Efectivo')
ON CONFLICT (name) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE countries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    code TEXT NOT NULL UNIQUE, -- "AR", "US", etc.
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO countries (name, code) VALUES
    ('Argentina', 'AR'),
    ('Estados Unidos', 'US')
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------

CREATE TABLE provinces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_id UUID NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL, -- "CBA", "BUE", etc.
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_province_code_country UNIQUE(country_id, code)
);

INSERT INTO provinces (country_id, name, code) VALUES
    ((SELECT id FROM countries WHERE code = 'AR' LIMIT 1), 'Buenos Aires', 'BUE'),
    ((SELECT id FROM countries WHERE code = 'AR' LIMIT 1), 'Córdoba', 'CBA'),
    ((SELECT id FROM countries WHERE code = 'AR' LIMIT 1), 'Santa Fe', 'SFE'),
    ((SELECT id FROM countries WHERE code = 'US' LIMIT 1), 'California', 'CA'),
    ((SELECT id FROM countries WHERE code = 'US' LIMIT 1), 'Texas', 'TX')
ON CONFLICT (country_id, code) DO NOTHING;


-- ============================================================================
-- USUARIOS
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    email_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMPTZ,
    name TEXT NOT NULL,
    phone TEXT,
    phone_verified BOOLEAN DEFAULT FALSE,
    avatar_url TEXT,
    password_hash TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_active ON users(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_users_created ON users(created_at DESC);


-- ============================================================================
-- TENANTS (Las tiendas)
-- ============================================================================

CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_plan_id UUID NOT NULL REFERENCES tenant_plans(id),
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    logo_url TEXT,
    cover_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_is_active ON tenants(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_tenants_plan ON tenants(tenant_plan_id);


-- ============================================================================
-- TENANT MEMBERS (Relación N:M usuario-tienda con rol)
-- ============================================================================

CREATE TABLE tenant_members (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_role_id UUID NOT NULL REFERENCES tenant_roles(id),
    invited_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
    joined_at TIMESTAMPTZ DEFAULT now(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tenant_id, user_id),
    CONSTRAINT fk_invited_by_tenant
        FOREIGN KEY (tenant_id, invited_by_id)
        REFERENCES tenant_members(tenant_id, user_id)
);

CREATE INDEX idx_tenant_members_user ON tenant_members(user_id);
CREATE INDEX idx_tenant_members_role ON tenant_members(tenant_role_id);
CREATE INDEX idx_tenant_members_active ON tenant_members(tenant_id, is_active) WHERE is_active = TRUE;


-- ============================================================================
-- TENANT SETTINGS - Configuración general de negocio y tienda
-- ============================================================================

CREATE TABLE tenant_settings (
    tenant_id UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    currency_id UUID NOT NULL REFERENCES currencies(id),
    -- Información del negocio
    business_name TEXT,
    business_email TEXT,
    business_phone TEXT,
    business_address TEXT,
    business_website TEXT,
    -- Configuración de tienda
    default_tax_rate NUMERIC(5, 2) DEFAULT 0,
    enable_shipping BOOLEAN DEFAULT TRUE,
    shipping_cost_default NUMERIC(12, 2),
    -- Configuraciones varias
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ============================================================================
-- TENANT PAYMENT GATEWAYS - Configuración de pagos agnóstica (datos sensibles)
-- ============================================================================

CREATE TABLE tenant_payment_gateways (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    payment_method_id UUID NOT NULL REFERENCES payment_methods(id) ON DELETE CASCADE,
    provider_name TEXT NOT NULL, -- Ej: 'mercado_pago', 'stripe', 'custom_transfer'
    credentials JSONB NOT NULL DEFAULT '{}', -- Tokens y public keys encriptadas
    is_active BOOLEAN DEFAULT FALSE,
    is_test_mode BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_tenant_payment_gateway UNIQUE(tenant_id, payment_method_id),
    CONSTRAINT unique_tenant_gateways_id_tenant UNIQUE(id, tenant_id)
);

CREATE INDEX idx_tenant_gateways_tenant ON tenant_payment_gateways(tenant_id);
CREATE INDEX idx_tenant_gateways_active ON tenant_payment_gateways(tenant_id, is_active) WHERE is_active = TRUE;


-- ============================================================================
-- TENANT EMAIL SETTINGS - Configuración de email (datos sensibles)
-- ============================================================================

CREATE TABLE tenant_email_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,
    smtp_host TEXT,
    smtp_port INT,
    smtp_username TEXT,
    smtp_password TEXT,  -- Encriptado en aplicación
    smtp_from_email TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_email_settings_tenant ON tenant_email_settings(tenant_id);


-- ============================================================================
-- INVITACIONES A TIENDAS
-- ============================================================================

CREATE TABLE tenant_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    tenant_role_id UUID NOT NULL REFERENCES tenant_roles(id),
    invited_by_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    accepted_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    token TEXT NOT NULL UNIQUE,
    accepted BOOLEAN DEFAULT FALSE,
    accepted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_invitations_tenant ON tenant_invitations(tenant_id);
CREATE INDEX idx_invitations_email ON tenant_invitations(email);
CREATE INDEX idx_invitations_token ON tenant_invitations(token);
CREATE INDEX idx_invitations_pending ON tenant_invitations(tenant_id, accepted) WHERE accepted = FALSE;


-- ============================================================================
-- SESIONES DE USUARIO
-- ============================================================================

CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    ip_address TEXT,
    user_agent TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_sessions_token ON user_sessions(token);
CREATE INDEX idx_sessions_active ON user_sessions(expires_at) WHERE revoked_at IS NULL;


-- ============================================================================
-- DIRECCIONES DE USUARIO (Globales)
-- ============================================================================

CREATE TABLE user_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_name TEXT NOT NULL,
    phone TEXT,
    address_line TEXT NOT NULL,
    floor_apt TEXT,
    province_id UUID NOT NULL REFERENCES provinces(id),
    city TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    label TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX unique_user_default_address ON user_addresses(user_id) WHERE is_default = TRUE;
CREATE INDEX idx_user_addresses_user ON user_addresses(user_id);
CREATE INDEX idx_user_addresses_default ON user_addresses(user_id, is_default) WHERE is_default = TRUE;


-- ============================================================================
-- AUDIT LOG DE USUARIOS
-- ============================================================================

CREATE TABLE user_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
    audit_action_id UUID REFERENCES audit_actions(id),
    resource_type_id UUID REFERENCES resource_types(id),
    resource_id UUID,
    ip_address TEXT,
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_user_audit_user ON user_audit_logs(user_id);
CREATE INDEX idx_user_audit_tenant ON user_audit_logs(tenant_id);
CREATE INDEX idx_user_audit_action ON user_audit_logs(audit_action_id);
CREATE INDEX idx_user_audit_created ON user_audit_logs(created_at DESC);


-- ============================================================================
-- CLIENTES (Por tienda)
-- ============================================================================

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    accepts_marketing BOOLEAN DEFAULT FALSE,
    notes TEXT,  -- notas internas del admin sobre este cliente
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_customer_per_tenant UNIQUE(tenant_id, user_id),
    CONSTRAINT unique_customers_id_tenant UNIQUE(id, tenant_id)
);

CREATE INDEX idx_customers_tenant ON customers(tenant_id);
CREATE INDEX idx_customers_user ON customers(user_id);


-- ============================================================================
-- CATEGORÍAS
-- ============================================================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    -- parent_id sin FK simple: la FK compuesta de abajo garantiza que
    -- la categoría padre pertenece al mismo tenant (aislamiento multitenant físico).
    parent_id UUID,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_category_per_tenant UNIQUE(tenant_id, slug),
    -- Expone (id, tenant_id) para que las tablas hijas puedan referenciar
    -- ambas columnas en sus FK compuestas.
    CONSTRAINT unique_categories_id_tenant UNIQUE (id, tenant_id),
    CONSTRAINT check_parent_different CHECK (id != parent_id),
    -- FK compuesta: garantiza que la categoría padre pertenece al mismo tenant.
    CONSTRAINT fk_categories_parent_tenant
        FOREIGN KEY (parent_id, tenant_id)
        REFERENCES categories(id, tenant_id)
        ON DELETE SET NULL
);

CREATE INDEX idx_categories_tenant ON categories(tenant_id);
CREATE INDEX idx_categories_parent ON categories(parent_id);


-- ============================================================================
-- ATRIBUTOS - TEMPLATE SYSTEM (3NF)
-- ============================================================================

CREATE TABLE attribute_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    -- category_id sin FK simple: la FK compuesta de abajo valida el tenant.
    category_id UUID NOT NULL,
    attribute_type_id UUID NOT NULL REFERENCES attribute_types(id),
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    is_filterable BOOLEAN DEFAULT TRUE,
    is_required BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_attribute_per_category UNIQUE(tenant_id, category_id, slug),
    -- Expone (id, tenant_id) para que attribute_options pueda referenciar ambas.
    CONSTRAINT unique_attribute_templates_id_tenant UNIQUE (id, tenant_id),
    -- FK compuesta: garantiza que la categoría referenciada pertenece al mismo tenant.
    CONSTRAINT fk_attribute_templates_category_tenant
        FOREIGN KEY (category_id, tenant_id)
        REFERENCES categories(id, tenant_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_attribute_templates_tenant ON attribute_templates(tenant_id);
CREATE INDEX idx_attribute_templates_category ON attribute_templates(category_id);
CREATE INDEX idx_attribute_templates_type ON attribute_templates(attribute_type_id);


-- ============================================================================
-- OPCIONES DE ATRIBUTOS (solo para type "select")
-- ============================================================================

CREATE TABLE attribute_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- tenant_id añadido para permitir la FK compuesta con attribute_templates.
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    -- attribute_template_id sin FK simple: la FK compuesta de abajo valida el tenant.
    attribute_template_id UUID NOT NULL,
    value TEXT NOT NULL,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_option_per_template UNIQUE(attribute_template_id, value),
    -- FK compuesta: garantiza que el template referenciado pertenece al mismo tenant.
    CONSTRAINT fk_attribute_options_template_tenant
        FOREIGN KEY (attribute_template_id, tenant_id)
        REFERENCES attribute_templates(id, tenant_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_attribute_options_tenant   ON attribute_options(tenant_id);
CREATE INDEX idx_attribute_options_template ON attribute_options(attribute_template_id);


-- ============================================================================
-- PRODUCTOS
-- ============================================================================

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    -- category_id sin FK simple: la FK compuesta de abajo valida el tenant.
    category_id UUID NOT NULL,
    product_status_id UUID NOT NULL REFERENCES product_statuses(id),
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    base_price NUMERIC(12, 2) NOT NULL CHECK (base_price >= 0),
    cost NUMERIC(12, 2) CHECK (cost IS NULL OR cost >= 0),
    sku TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_product_slug_per_tenant UNIQUE(tenant_id, slug),
    -- Expone (id, tenant_id) para que product_variants e images puedan
    -- referenciar ambas columnas en sus FK compuestas.
    CONSTRAINT unique_products_id_tenant UNIQUE (id, tenant_id),
    -- FK compuesta: garantiza que la categoría referenciada pertenece al mismo tenant.
    CONSTRAINT fk_products_category_tenant
        FOREIGN KEY (category_id, tenant_id)
        REFERENCES categories(id, tenant_id)
);

CREATE INDEX idx_products_tenant ON products(tenant_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(product_status_id);
CREATE INDEX idx_products_tenant_status_category ON products(tenant_id, product_status_id, category_id);


-- ============================================================================
-- VARIANTES DE PRODUCTOS
-- Los atributos se guardan en JSONB y se validan contra attribute_templates
-- en la capa de aplicación.
-- Ejemplo: {"color": "Rojo", "talle": "M"}
-- ============================================================================

CREATE TABLE product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    -- product_id sin FK simple: la FK compuesta de abajo valida el tenant.
    product_id UUID NOT NULL,
    sku TEXT NOT NULL,
    -- Modelo Híbrido: los atributos se almacenan en JSONB y se validan
    -- contra attribute_templates en la capa de aplicación.
    -- Ejemplo: {"color": "Rojo", "talle": "M"}
    attributes JSONB NOT NULL DEFAULT '{}',
    price NUMERIC(12, 2) CHECK (price IS NULL OR price >= 0),
    cost NUMERIC(12, 2) CHECK (cost IS NULL OR cost >= 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    reserved_stock INT NOT NULL DEFAULT 0 CHECK (reserved_stock >= 0),
    barcode TEXT,
    weight_grams INT CHECK (weight_grams IS NULL OR weight_grams > 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_variant_sku_per_tenant UNIQUE(tenant_id, sku),
    CONSTRAINT check_reserved_not_more_than_stock CHECK (reserved_stock <= stock),
    -- Expone (id, tenant_id) para que product_images pueda referenciar ambas.
    CONSTRAINT unique_product_variants_id_tenant UNIQUE (id, tenant_id),
    -- FK compuesta: garantiza que el producto referenciado pertenece al mismo tenant.
    CONSTRAINT fk_product_variants_product_tenant
        FOREIGN KEY (product_id, tenant_id)
        REFERENCES products(id, tenant_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_variants_tenant ON product_variants(tenant_id);
CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_variants_attributes ON product_variants USING GIN(attributes);
CREATE INDEX idx_variants_stock_low ON product_variants(tenant_id, stock) WHERE stock < 10;


-- ============================================================================
-- IMÁGENES DE PRODUCTOS
-- ============================================================================

CREATE TABLE product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    -- product_id y variant_id sin FK simple: las FK compuestas de abajo validan el tenant.
    product_id UUID NOT NULL,
    variant_id UUID,
    image_url TEXT NOT NULL,
    alt_text TEXT,
    display_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT check_order_positive CHECK (display_order >= 0),
    -- FK compuesta: garantiza que el producto referenciado pertenece al mismo tenant.
    CONSTRAINT fk_product_images_product_tenant
        FOREIGN KEY (product_id, tenant_id)
        REFERENCES products(id, tenant_id)
        ON DELETE CASCADE,
    -- FK compuesta (nullable): garantiza que la variante referenciada pertenece
    -- al mismo tenant. PostgreSQL usa MATCH SIMPLE por defecto, lo que permite
    -- que variant_id sea NULL sin violar la restricción.
    CONSTRAINT fk_product_images_variant_tenant
        FOREIGN KEY (variant_id, tenant_id)
        REFERENCES product_variants(id, tenant_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_product_images_tenant ON product_images(tenant_id);
CREATE INDEX idx_product_images_product ON product_images(product_id);
CREATE INDEX idx_product_images_variant ON product_images(variant_id);


-- ============================================================================
-- CARRITOS (Por tienda)
-- ============================================================================

CREATE TABLE carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    guest_email TEXT,
    recovery_token TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'converted', 'abandoned')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_carts_id_tenant UNIQUE (id, tenant_id)
);

CREATE INDEX idx_carts_tenant ON carts(tenant_id);
CREATE INDEX idx_carts_user ON carts(user_id);
CREATE INDEX idx_carts_token ON carts(recovery_token);
CREATE INDEX idx_carts_status ON carts(tenant_id, status);

-- ----------------------------------------------------------------------------

CREATE TABLE cart_items (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    cart_id UUID NOT NULL,
    product_variant_id UUID NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tenant_id, cart_id, product_variant_id),
    CONSTRAINT fk_cart_items_cart_tenant
        FOREIGN KEY (cart_id, tenant_id)
        REFERENCES carts(id, tenant_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_variant_tenant
        FOREIGN KEY (product_variant_id, tenant_id)
        REFERENCES product_variants(id, tenant_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);


-- ============================================================================
-- ÓRDENES (Por tienda)
-- ============================================================================

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL,
    order_number TEXT NOT NULL,
    status_id UUID NOT NULL REFERENCES order_statuses(id),
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    shipping_cost NUMERIC(12,2) DEFAULT 0,
    tax NUMERIC(12,2) DEFAULT 0,
    discount NUMERIC(12,2) DEFAULT 0,
    total NUMERIC(12,2) NOT NULL CHECK (total >= 0),
    payment_expires_at TIMESTAMPTZ, -- Fecha límite para que el worker libere el stock
    customer_notes TEXT,
    admin_notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_order_number_per_tenant UNIQUE(tenant_id, order_number),
    CONSTRAINT unique_orders_id_tenant UNIQUE(id, tenant_id),
    CONSTRAINT fk_orders_customer_tenant
        FOREIGN KEY (customer_id, tenant_id)
        REFERENCES customers(id, tenant_id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_orders_tenant ON orders(tenant_id);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(tenant_id, status_id);
CREATE INDEX idx_orders_created ON orders(tenant_id, created_at DESC);
-- Índice parcial: Solo rastrea órdenes que pueden expirar, vital para la performance del background worker
CREATE INDEX idx_orders_expiration ON orders(payment_expires_at) WHERE payment_expires_at IS NOT NULL;


-- ============================================================================
-- DETALLES DE ORDEN (Por tienda)
-- ============================================================================

CREATE TABLE order_items (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_id UUID NOT NULL,
    product_variant_id UUID NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    subtotal NUMERIC(12,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tenant_id, order_id, product_variant_id),
    CONSTRAINT fk_order_items_order_tenant
        FOREIGN KEY (order_id, tenant_id)
        REFERENCES orders(id, tenant_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_order_items_variant_tenant
        FOREIGN KEY (product_variant_id, tenant_id)
        REFERENCES product_variants(id, tenant_id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_order_items_order ON order_items(order_id);


-- ============================================================================
-- ENVÍOS (Por tienda - Snapshot de dirección)
-- ============================================================================

CREATE TABLE order_shipments (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_id UUID NOT NULL,
    recipient_name TEXT NOT NULL,
    phone TEXT,
    address_line TEXT NOT NULL,
    floor_apt TEXT,
    city_name TEXT NOT NULL,
    province_name TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    carrier TEXT,
    tracking_number TEXT,
    status_id UUID NOT NULL REFERENCES shipment_statuses(id),
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tenant_id, order_id),
    CONSTRAINT fk_shipments_order_tenant
        FOREIGN KEY (order_id, tenant_id)
        REFERENCES orders(id, tenant_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_shipments_status ON order_shipments(tenant_id, status_id);


-- ============================================================================
-- PAGOS (Por tienda)
-- ============================================================================

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    order_id UUID NOT NULL,
    external_id TEXT,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    method_id UUID NOT NULL REFERENCES payment_methods(id),
    status_id UUID NOT NULL REFERENCES payment_statuses(id),
    metadata JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_payments_id_tenant UNIQUE(id, tenant_id),
    CONSTRAINT fk_payments_order_tenant
        FOREIGN KEY (order_id, tenant_id)
        REFERENCES orders(id, tenant_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_payments_tenant ON payments(tenant_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_method ON payments(method_id);
CREATE INDEX idx_payments_status ON payments(tenant_id, status_id);


-- ============================================================================
-- TRIGGERS PARA updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo actualiza si los datos de la fila entera realmente cambiaron
    IF ROW(NEW.*) IS DISTINCT FROM ROW(OLD.*) THEN
        NEW.updated_at = now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tenants_updated_at
    BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tenant_settings_updated_at
    BEFORE UPDATE ON tenant_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tenant_payment_gateways_updated_at
    BEFORE UPDATE ON tenant_payment_gateways
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tenant_email_settings_updated_at
    BEFORE UPDATE ON tenant_email_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tenant_members_updated_at
    BEFORE UPDATE ON tenant_members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attribute_templates_updated_at
    BEFORE UPDATE ON attribute_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attribute_options_updated_at
    BEFORE UPDATE ON attribute_options
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_variants_updated_at
    BEFORE UPDATE ON product_variants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_order_shipments_updated_at
    BEFORE UPDATE ON order_shipments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_addresses_updated_at
    BEFORE UPDATE ON user_addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_carts_updated_at
    BEFORE UPDATE ON carts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cart_items_updated_at
    BEFORE UPDATE ON cart_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- VISTAS ÚTILES
-- ============================================================================

-- Permisos completos por usuario y tienda
CREATE VIEW user_tenant_permissions AS
SELECT
    u.id AS user_id,
    u.email,
    u.name,
    t.id AS tenant_id,
    t.slug,
    t.name AS tenant_name,
    tr.name AS role_name,
    tr.permissions,
    tm.joined_at,
    tm.is_active
FROM users u
JOIN tenant_members tm ON u.id = tm.user_id
JOIN tenants t ON tm.tenant_id = t.id
JOIN tenant_roles tr ON tm.tenant_role_id = tr.id
WHERE u.is_active = TRUE AND tm.is_active = TRUE AND t.is_active = TRUE;

-- Lista de tiendas por usuario
CREATE VIEW user_tenants_list AS
SELECT
    u.id AS user_id,
    u.email,
    u.name,
    json_agg(
        json_build_object(
            'tenant_id', t.id,
            'slug',      t.slug,
            'name',      t.name,
            'logo_url',  t.logo_url,
            'role',      tr.name,
            'joined_at', tm.joined_at
        ) ORDER BY t.name
    ) AS tenants
FROM users u
JOIN tenant_members tm ON u.id = tm.user_id
JOIN tenants t ON tm.tenant_id = t.id
JOIN tenant_roles tr ON tm.tenant_role_id = tr.id
WHERE u.is_active = TRUE AND tm.is_active = TRUE AND t.is_active = TRUE
GROUP BY u.id, u.email, u.name;

-- Atributos de categoría con sus opciones
CREATE VIEW category_attributes_with_options AS
SELECT
    at.id AS template_id,
    at.category_id,
    at.name AS attribute_name,
    at.slug,
    aty.name AS attribute_type,
    at.is_required,
    at.is_filterable,
    json_agg(
        json_build_object(
            'id',            ao.id,
            'value',         ao.value,
            'display_order', ao.display_order
        ) ORDER BY ao.display_order
    ) FILTER (WHERE ao.id IS NOT NULL) AS options
FROM attribute_templates at
JOIN attribute_types aty ON at.attribute_type_id = aty.id
LEFT JOIN attribute_options ao ON at.id = ao.attribute_template_id AND ao.is_active = TRUE
WHERE at.is_active = TRUE
GROUP BY at.id, at.category_id, at.name, at.slug, aty.name, at.is_required, at.is_filterable
ORDER BY at.display_order;

-- Productos con estado y categoría legibles
CREATE VIEW products_with_status AS
SELECT
    p.id,
    p.tenant_id,
    p.name,
    p.slug,
    p.base_price,
    p.cost,
    ps.name AS status,
    c.name  AS category_name,
    p.created_at,
    p.updated_at
FROM products p
JOIN product_statuses ps ON p.product_status_id = ps.id
JOIN categories c ON p.category_id = c.id
WHERE p.is_active = TRUE;

-- Órdenes con estado legible
CREATE VIEW orders_with_status AS
SELECT
    o.id, o.tenant_id, o.order_number, o.total,
    os.name AS status,
    c.user_id AS customer_user_id,
    o.created_at, o.updated_at
FROM orders o
JOIN order_statuses os ON o.status_id = os.id
JOIN customers c ON o.customer_id = c.id
WHERE o.is_active = TRUE;

-- Órdenes con cliente y tienda
CREATE VIEW orders_complete AS
SELECT
    o.id, o.tenant_id, o.order_number,
    u.email, u.name,
    t.name AS tenant_name,
    os.name AS status,
    o.total, o.created_at
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN users u ON c.user_id = u.id
JOIN tenants t ON o.tenant_id = t.id
JOIN order_statuses os ON o.status_id = os.id
WHERE o.is_active = TRUE;

-- Detalles de orden con producto
CREATE VIEW order_items_with_product AS
SELECT
    oi.tenant_id, oi.order_id, oi.product_variant_id, oi.quantity, oi.unit_price,
    p.name AS product_name,
    pv.sku,
    oi.subtotal
FROM order_items oi
JOIN product_variants pv ON oi.product_variant_id = pv.id
JOIN products p ON pv.product_id = p.id
WHERE oi.is_active = TRUE;


-- ============================================================================
-- FIN DEL SCRIPT
-- (Las semillas de inicialización por defecto se definieron directamente debajo
-- de la creación de cada una de sus respectivas tablas de catálogo/referencia).
-- ============================================================================
