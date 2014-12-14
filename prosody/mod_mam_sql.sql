CREATE TABLE prosodyarchive (
    id bigserial,
    host varchar(1023) NOT NULL,
    "user" varchar(1023) NOT NULL,
    store varchar(1023) NOT NULL,
    "when" INTEGER NOT NULL,
    "with" varchar(2047) NOT NULL,
    "resource" varchar(1023),
    stanza TEXT NOT NULL
);
CREATE INDEX hus ON prosodyarchive (host, "user", store);
CREATE INDEX "with" ON prosodyarchive ("with");
CREATE INDEX thetime ON prosodyarchive ("when");
