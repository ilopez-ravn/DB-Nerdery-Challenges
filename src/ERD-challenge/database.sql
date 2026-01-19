-- USER DATA

CREATE TABLE IF NOT EXISTS user_role (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS sys_user (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role_id INT REFERENCES user_role(id) ON DELETE RESTRICT,
    email VARCHAR(100) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated_password TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);




-- PRODUCT DATA

CREATE TABLE IF NOT EXISTS category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_by INT REFERENCES sys_user(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product (
    id SERIAL PRIMARY KEY,
    name VARCHAR(500) NOT NULL,
    description TEXT,
    created_by INT REFERENCES sys_user(id) ON DELETE SET NULL,
    price DECIMAL(10, 2) NOT NULL,
    category_id INT REFERENCES category(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_changes_log (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES product(id) ON DELETE CASCADE,
    changed_by INT REFERENCES sys_user(id) ON DELETE SET NULL,
    change_description TEXT NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_image (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES product(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warehouse (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_stock (
    id SERIAL PRIMARY KEY,
    product_id INT REFERENCES product(id) ON DELETE CASCADE,
    warehouse_id INT REFERENCES warehouse(id) ON DELETE CASCADE,
    quantity INT NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warehouse_kardex (
    id SERIAL PRIMARY KEY,
    product_id INT ,
    warehouse_id INT ,
    change_type VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by INT REFERENCES sys_user(id) ON DELETE SET NULL,
    notes TEXT
);




-- CLIENT DATA

CREATE TABLE IF NOT EXISTS client (
    id SERIAL PRIMARY KEY,

    document VARCHAR(50) UNIQUE NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    username VARCHAR(50) UNIQUE NOT NULL,
    password TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS client_address (
    id SERIAL PRIMARY KEY,
    client_id INT REFERENCES client(id) ON DELETE CASCADE,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'Peru',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- SALES DATA

CREATE TABLE IF NOT EXISTS shopping_cart (
    id SERIAL PRIMARY KEY,
    client_id INT REFERENCES client(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shopping_cart_details (
    id SERIAL PRIMARY KEY,
    cart_id INT REFERENCES shopping_cart(id) ON DELETE CASCADE,
    product_id INT REFERENCES product(id) ON DELETE CASCADE,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    total DECIMAL(10, 2) GENERATED ALWAYS AS (price * quantity) STORED,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_liked (
    id SERIAL PRIMARY KEY,
    client_id INT REFERENCES client(id) ON DELETE CASCADE,
    product_id INT REFERENCES product(id) ON DELETE CASCADE,
    liked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sales (
    id SERIAL PRIMARY KEY,
    client_id INT REFERENCES client(id) ON DELETE CASCADE,
    address_id INT REFERENCES client_address(id) ON DELETE SET NULL,
    warehouse_id INT REFERENCES warehouse(id) ON DELETE SET NULL,
    
    tax_percent INT NOT NULL DEFAULT 18,
    total_amount DECIMAL(10, 2) NOT NULL,
    delivery_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10, 2) NOT NULL GENERATED ALWAYS AS ( (total_amount + delivery_fee) - ((total_amount + delivery_fee) / 1.18) ) STORED,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS sales_details (
    id SERIAL PRIMARY KEY,
    sale_id INT REFERENCES sales(id) ON DELETE CASCADE,
    product_id INT REFERENCES product(id) ON DELETE CASCADE,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    tax_percent INT NOT NULL DEFAULT 18,
    total_amount DECIMAL(10, 2) GENERATED ALWAYS AS (price * quantity) STORED,
    tax_amount DECIMAL(10, 2) NOT NULL GENERATED ALWAYS AS ( (price * quantity) - ((price * quantity) / 1.18)) STORED
);

CREATE TABLE IF NOT EXISTS stripe_payment_information (
    id SERIAL PRIMARY KEY,
    sale_id INT REFERENCES sales(id) ON DELETE CASCADE,
    stripe_payment_id VARCHAR(255) UNIQUE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    payment_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS delivery_tracking (
    id SERIAL PRIMARY KEY,
    sale_id INT REFERENCES sales(id) ON DELETE CASCADE,
    address_id INT REFERENCES client_address(id) ON DELETE SET NULL,
    tracking_number VARCHAR(100) UNIQUE NOT NULL,
    carrier VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    estimated_delivery_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sale_tracking_log (
    id SERIAL PRIMARY KEY,
    sale_id INT REFERENCES sales(id) ON DELETE CASCADE,
    previous_status VARCHAR(50) NOT NULL,
    new_status VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Table for emails sent when liked product has 3 remaining stock
-- And for the password recovery emails

CREATE TABLE IF NOT EXISTS email_log (
    id SERIAL PRIMARY KEY,
    recipient_email VARCHAR(100) NOT NULL,
    cc VARCHAR(100),
    bcc VARCHAR(100),
    subject VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS password_recovery_token (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES sys_user(id) ON DELETE CASCADE,
    client_id INT REFERENCES client(id) ON DELETE CASCADE,
    recovery_token VARCHAR(255) UNIQUE NOT NULL,
    token_expiry TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- We can later add product variants and better audit logging 

-- INDEXES

-- VIEWS

-- TRIGGERS