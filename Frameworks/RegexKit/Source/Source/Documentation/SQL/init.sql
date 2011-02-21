PRAGMA synchronous = OFF;

BEGIN;


CREATE TABLE version (
vid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
major INTEGER NOT NULL,
minor INTEGER NOT NULL,
point INTEGER NOT NULL,
UNIQUE (major, minor, point)
);

INSERT INTO version (major, minor, point) VALUES (0, 2, 0);
INSERT INTO version (major, minor, point) VALUES (0, 3, 0);
INSERT INTO version (major, minor, point) VALUES (0, 4, 0);
INSERT INTO version (major, minor, point) VALUES (0, 5, 0);
INSERT INTO version (major, minor, point) VALUES (0, 6, 0);



CREATE TABLE versionCrossRef (
ivid INTEGER REFERENCES version ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
dvid INTEGER REFERENCES version ON DELETE CASCADE ON UPDATE CASCADE,
rvid INTEGER REFERENCES version ON DELETE CASCADE ON UPDATE CASCADE,
deprecatedSummary TEXT,
bitSize INTEGER NOT NULL,
tbl TEXT NOT NULL,
id INTEGER NOT NULL,
UNIQUE(ivid, bitSize, tbl, id)
);

CREATE INDEX vcr_tbl_id_idx ON versionCrossRef (tbl, id);


CREATE VIEW v_versionXRef AS 
SELECT
vcr.ivid AS ivid, vcr.dvid AS dvid, vcr.rvid AS rvid, vcr.deprecatedSummary AS deprecatedSummary, vcr.bitSize AS bitSize, vcr.tbl AS tbl, vcr.id AS id,
iv.major || '.' || iv.minor || '.' || iv.point AS intro,
(SELECT CASE WHEN dvid IS NOT NULL THEN dv.major || '.' || dv.minor || '.' || dv.point ELSE NULL END) AS depre,
(SELECT CASE WHEN rvid IS NOT NULL THEN rv.major || '.' || rv.minor || '.' || rv.point ELSE NULL END) AS removed
FROM versionCrossRef AS vcr
JOIN version AS iv ON iv.vid = vcr.ivid
LEFT JOIN version AS dv ON dv.vid = vcr.dvid
LEFT JOIN version AS rv ON rv.vid = vcr.rvid
;

/*
CREATE TRIGGER ins_v_vcr BEFORE INSERT ON versionCrossRef BEGIN SELECT CASE 
WHEN (SELECT count(*) FROM version AS v1, versionCrossRef AS vcr JOIN version AS v2 ON vcr.ivid = v2.vid WHERE v1.vid = NEW.ivid AND vcr.tbl = NEW.tbl AND vcr.id = NEW.id AND v1.bitSize = v2.bitSize) > 0 THEN RAISE(ABORT,'Only a single "Introduced in Version" per bit size permitted.')
WHEN (SELECT count(*) FROM version AS v1, versionCrossRef AS vcr JOIN version AS v2 ON vcr.dvid = v2.vid WHERE v1.vid = NEW.dvid AND vcr.tbl = NEW.tbl AND vcr.id = NEW.id AND v1.bitSize = v2.bitSize) > 0 THEN RAISE(ABORT,'Only a single "Deprecated in Version" per bit size permitted.')
END; END;

CREATE TRIGGER upd_v_vcr BEFORE UPDATE ON versionCrossRef BEGIN SELECT CASE 
WHEN (SELECT count(*) FROM version AS v1, versionCrossRef AS vcr JOIN version AS v2 ON vcr.ivid = v2.vid WHERE v1.vid = NEW.ivid AND vcr.tbl = NEW.tbl AND vcr.id = NEW.id AND v1.bitSize = v2.bitSize) > 0 THEN RAISE(ABORT,'Only a single "Introduced in Version" per bit size permitted.')
WHEN (SELECT count(*) FROM version AS v1, versionCrossRef AS vcr JOIN version AS v2 ON vcr.dvid = v2.vid WHERE v1.vid = NEW.dvid AND vcr.tbl = NEW.tbl AND vcr.id = NEW.id AND v1.bitSize = v2.bitSize) > 0 THEN RAISE(ABORT,'Only a single "Deprecated in Version" per bit size permitted.')
END; END;
*/




CREATE TABLE tagKeywords (
tkid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
keyword TEXT NOT NULL UNIQUE ON CONFLICT FAIL,
arguments INTEGER NOT NULL DEFAULT 1,
multiple INTEGER NOT NULL DEFAULT 0
);

/* See trigger ins_tags for single/multiple tags constraint in a single headerdoc comment */
/*(abstract category class comment const constant discussion function group header interface method param result seealso toc tocgroup typedef)*/

INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("abstract",   1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("category",   1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("class",      1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("comment",    1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("const",      1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("constant",   2, 1);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("defined",    1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("discussion", 1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("function",   1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("group",      1, 1);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("header",     1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("interface",  1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("method",     1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("param",      2, 1);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("result",     1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("seealso",    1, 1);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("toc",        1, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("tocgroup",   2, 0);
INSERT INTO tagKeywords (keyword, arguments, multiple) VALUES ("typedef",    1, 0);


CREATE TABLE headers (
hid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
path TEXT NOT NULL,
fileName TEXT NOT NULL,
size INTEGER NOT NULL,
modified TEXT NOT NULL,
UNIQUE (path, fileName) ON CONFLICT FAIL
);


CREATE TABLE headerDocComments (
hdcid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
hid INTEGER REFERENCES headers ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
fullText TEXT,
UNIQUE(hid, startsAt) ON CONFLICT FAIL
);


CREATE TABLE tags (
tid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
tkid INTEGER REFERENCES tagKeywords ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
hdcid INTEGER REFERENCES headerDocComments ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
position INTEGER NOT NULL,
fullText TEXT,
UNIQUE(hdcid, position) ON CONFLICT FAIL
);

/* Logic to enforce whether or not a tag can appear more than once in a headerdoc comment */

CREATE TRIGGER ins_tags BEFORE INSERT ON tags BEGIN SELECT CASE WHEN (SELECT tkid FROM tagKeywords WHERE multiple = 0 AND tkid = NEW.tkid) AND (SELECT t.tid FROM tags AS t WHERE t.hdcid = new.hdcid AND t.tkid = new.tkid) THEN raise(abort,'Multiple tag entries not allowed') end; end;


CREATE TABLE tagArguments (
taid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
tid INTEGER REFERENCES tags ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
argument INTEGER NOT NULL,
argText TEXT NOT NULL,
UNIQUE(tid, argument) ON CONFLICT FAIL
);

CREATE TABLE define (
did INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
hid INTEGER REFERENCES headers ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
hdcid INTEGER REFERENCES headerDocComments ON DELETE CASCADE ON UPDATE CASCADE,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
defineName TEXT NOT NULL,
leftHandSide TEXT,
rightHandSide TEXT,
fullText TEXT,
cppLeftHandSide TEXT,
cppRightHandSide TEXT,
cppText TEXT,
UNIQUE(hid, defineName) ON CONFLICT FAIL
);

CREATE TABLE constant (
cid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
hid INTEGER REFERENCES headers ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
hdcid INTEGER REFERENCES headerDocComments ON DELETE CASCADE ON UPDATE CASCADE,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
name TEXT NOT NULL,
fullText TEXT,
UNIQUE(hid, name) ON CONFLICT FAIL
);


CREATE TABLE typedefEnum (
tdeid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
hid INTEGER REFERENCES headers ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
hdcid INTEGER REFERENCES headerDocComments ON DELETE CASCADE ON UPDATE CASCADE,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
position INTEGER NOT NULL,
fullText TEXT,
name TEXT NOT NULL,
enumText TEXT NOT NULL,
UNIQUE(hid, name) ON CONFLICT FAIL
);


CREATE TABLE enumIdentifier (
eid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
tdeid INTEGER REFERENCES tags ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
hdcid INTEGER REFERENCES headerDocComments ON DELETE CASCADE ON UPDATE CASCADE,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
position INTEGER NOT NULL,
fullText TEXT,
identifier TEXT NOT NULL,
constant TEXT NOT NULL,
UNIQUE(tdeid, identifier, constant) ON CONFLICT FAIL
);


CREATE TABLE objCMethods (
ocmid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
occlid INTEGER REFERENCES objCClass ON DELETE CASCADE ON UPDATE CASCADE,
hid INTEGER REFERENCES headers ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
hdcid INTEGER REFERENCES headerDocComments ON DELETE CASCADE ON UPDATE CASCADE,
tocid INTEGER REFERENCES toc ON DELETE CASCADE ON UPDATE CASCADE,
tgid INTEGER REFERENCES tocGroup ON DELETE CASCADE ON UPDATE CASCADE,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
type TEXT(1) NOT NULL,
fullText TEXT,
prettyText TEXT NOT NULL,
signature TEXT NOT NULL,
selector TEXT NOT NULL,
UNIQUE(hid, selector) ON CONFLICT FAIL
);


CREATE TABLE objCClass (
occlid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
class TEXT NOT NULL UNIQUE
);


CREATE TABLE objCClassCategory (
occlcatid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
hid INTEGER REFERENCES headers ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
occlid INTEGER REFERENCES objCClass ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
category TEXT NOT NULL,
protocols TEXT,
methodsStart INTEGER NOT NULL,
methodsLength INTEGER NOT NULL,
UNIQUE(occlid, category)
);


CREATE TABLE objCClassDefinition (
occldefid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
hid INTEGER REFERENCES headers ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
occlid INTEGER REFERENCES objCClass ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
scclid INTEGER REFERENCES objCClass ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
protocols TEXT,
ivars TEXT,
methodsStart INTEGER NOT NULL,
methodsLength INTEGER NOT NULL,
UNIQUE(occlid) ON CONFLICT FAIL
);


CREATE TABLE prototypes (
pid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
hid INTEGER REFERENCES headers ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
hdcid INTEGER REFERENCES headerDocComments ON DELETE CASCADE ON UPDATE CASCADE,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
fullText TEXT,
prettyText TEXT NOT NULL,
signature TEXT NOT NULL,
sym TEXT NOT NULL,
UNIQUE(hid, signature) ON CONFLICT FAIL
);


CREATE TABLE functions (
fid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
hid INTEGER REFERENCES headers ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
startsAt INTEGER NOT NULL,
length INTEGER NOT NULL,
fullText TEXT,
prettyText TEXT NOT NULL,
signature TEXT NOT NULL,
sym TEXT NOT NULL,
UNIQUE(hid, signature) ON CONFLICT FAIL
);


CREATE TABLE tocGroup (
tgid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
groupName TEXT NOT NULL UNIQUE ON CONFLICT IGNORE
);


CREATE TABLE toc (
tocid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
tocName TEXT NOT NULL UNIQUE ON CONFLICT IGNORE
);


CREATE TABLE tocMembers (
tocid INTEGER REFERENCES toc ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
tgid INTEGER REFERENCES tocGroup ON DELETE CASCADE ON UPDATE CASCADE NOT NULL,
pos INTEGER NOT NULL,
UNIQUE(tocid, tgid)
);


/* These triggers create the functionality of the ignored by sqlite3 'ON DELETE/UPDATE' clauses*/

/*
CREATE TRIGGER del_tocid_tocMembers DELETE ON toc BEGIN DELETE FROM tocMembers WHERE tocid = OLD.tocid; END;
CREATE TRIGGER del_tgid_tocMembers DELETE ON tocGroup BEGIN DELETE FROM tocMembers WHERE tgid = OLD.tgid; END;
CREATE TRIGGER del_tgid_objCMethods DELETE ON tocGroup BEGIN UPDATE objCMethods SET tgid = NULL WHERE tgid = OLD.tgid; END;
CREATE TRIGGER del_tgid_prototypes DELETE ON tocGroup BEGIN UPDATE prototypes SET tgid = NULL WHERE tgid = OLD.tgid; END;


CREATE TRIGGER upd_tocid_tocMembers UPDATE OF tocid ON toc BEGIN UPDATE tocMembers SET tocid = NEW.tocid WHERE tocid = OLD.tocid; END;
CREATE TRIGGER upd_tgid_tocMembers UPDATE OF tgid ON tocGroup BEGIN UPDATE tocMembers SET tgid = NEW.tgid WHERE tgid = OLD.tgid; END;
CREATE TRIGGER ups_tgid_objCMethods UPDATE OF tgid ON tocGroup BEGIN UPDATE objCMethods SET tgid = NEW.tgid WHERE tgid = OLD.tgid; END;
CREATE TRIGGER ups_tgid_prototypes UPDATE OF tgid ON tocGroup BEGIN UPDATE prototypes SET tgid = NEW.tgid WHERE tgid = OLD.tgid; END;

CREATE TRIGGER del_hdcid_tags DELETE ON headerDocComments BEGIN DELETE FROM tags WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER del_hdcid_constant DELETE ON headerDocComments BEGIN DELETE FROM constant WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER del_hdcid_typedefEnum DELETE ON headerDocComments BEGIN DELETE FROM typedefEnum WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER del_hdcid_enumIdentifier DELETE ON headerDocComments BEGIN DELETE FROM enumIdentifier WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER del_hdcid_objCMethods DELETE ON headerDocComments BEGIN DELETE FROM objCMethods WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER del_hdcid_prototypes DELETE ON headerDocComments BEGIN DELETE FROM prototypes WHERE hdcid = OLD.hdcid; END;

CREATE TRIGGER del_tkid_tags DELETE ON tagKeywords BEGIN DELETE FROM tags WHERE tkid = OLD.tkid; END;
CREATE TRIGGER del_tid_tagArguments DELETE ON tags BEGIN DELETE FROM tagArguments WHERE tid = OLD.tid; END;
CREATE TRIGGER del_hid_headerDocComments DELETE ON headers BEGIN DELETE FROM headerDocComments WHERE hid = OLD.hid; END;
CREATE TRIGGER del_hid_objcmethods DELETE ON headers BEGIN DELETE FROM objcmethods WHERE hid = OLD.hid; END;
CREATE TRIGGER del_hid_prototypes DELETE ON headers BEGIN DELETE FROM prototypes WHERE hid = OLD.hid; END;
CREATE TRIGGER del_hid_functions DELETE ON headers BEGIN DELETE FROM functions WHERE hid = OLD.hid; END;
CREATE TRIGGER del_hid_typedefEnum DELETE ON headers BEGIN DELETE FROM typedefEnum WHERE hid = OLD.hid; END;
CREATE TRIGGER del_tdeid_enumIdentifier DELETE ON typedefEnum BEGIN DELETE FROM enumIdentifier WHERE tdeid = OLD.tdeid; END;
CREATE TRIGGER del_hid_objCClassCategory DELETE ON headers BEGIN DELETE FROM objCClassCategory WHERE hid = OLD.hid; END;
CREATE TRIGGER del_hid_objCClassDefinition DELETE ON headers BEGIN DELETE FROM objCClassDefinition WHERE hid = OLD.hid; END;
CREATE TRIGGER del_occlid_objCClassCategory DELETE ON objCClass BEGIN DELETE FROM objCClassCategory WHERE occlid = OLD.occlid; END;
CREATE TRIGGER del_occlid_objCClassDefinition DELETE ON objCClass BEGIN DELETE FROM objCClassDefinition WHERE occlid = OLD.occlid; END;
CREATE TRIGGER del_scclid_objCClassDefinition DELETE ON objCClass BEGIN DELETE FROM objCClassDefinition WHERE scclid = OLD.occlid; END;

CREATE TRIGGER upd_hdcid_tags UPDATE OF hdcid ON headerDocComments BEGIN UPDATE tags SET hdcid = NEW.hdcid WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER upd_hdcid_constant UPDATE OF hdcid ON headerDocComments BEGIN UPDATE constant SET hdcid = NEW.hdcid WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER upd_hdcid_typedefEnum UPDATE OF hdcid ON headerDocComments BEGIN UPDATE typedefEnum SET hdcid = NEW.hdcid WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER upd_hdcid_enumIdentifier UPDATE OF hdcid ON headerDocComments BEGIN UPDATE enumIdentifier SET hdcid = NEW.hdcid WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER upd_hdcid_objCMethods UPDATE OF hdcid ON headerDocComments BEGIN UPDATE objCMethods SET hdcid = NEW.hdcid WHERE hdcid = OLD.hdcid; END;
CREATE TRIGGER upd_hdcid_prototypes UPDATE OF hdcid ON headerDocComments BEGIN UPDATE prototypes SET hdcid = NEW.hdcid WHERE hdcid = OLD.hdcid; END;

CREATE TRIGGER upd_tkid_tags UPDATE OF tkid ON tagKeywords BEGIN UPDATE tags SET tkid = NEW.tkid WHERE tkid = OLD.tkid; END;
CREATE TRIGGER upd_tid_tagArguments UPDATE OF tid ON tags BEGIN UPDATE tagArguments SET tid = NEW.tid WHERE tid = OLD.tid; END;
CREATE TRIGGER upd_hid_headerDocComments UPDATE OF hid ON headers BEGIN UPDATE headerDocComments SET hid = NEW.hid WHERE hid = OLD.hid; END;
CREATE TRIGGER upd_hid_objcmethods UPDATE OF hid ON headers BEGIN UPDATE objcmethods SET hid = NEW.hid WHERE hid = OLD.hid; END;
CREATE TRIGGER upd_hid_prototypes UPDATE OF hid ON headers BEGIN UPDATE prototypes SET hid = NEW.hid WHERE hid = OLD.hid; END;
CREATE TRIGGER upd_hid_functions UPDATE OF hid ON headers BEGIN UPDATE functions SET hid = NEW.hid WHERE hid = OLD.hid; END;
CREATE TRIGGER upd_hid_typedefEnum UPDATE OF hid  ON headers BEGIN UPDATE typedefEnum SET hid = NEW.hid WHERE hid = OLD.hid; END;
CREATE TRIGGER upd_tdeid_enumIdentifier UPDATE OF tdeid ON typedefEnum BEGIN UPDATE enumIdentifier SET tdeid = NEW.tdeiid WHERE tdeid = OLD.tdeid; END;
CREATE TRIGGER upd_hid_objCClassCategory UPDATE OF hid ON headers BEGIN UPDATE objCClassCategory SET hid = NEW.hid WHERE hid = OLD.hid; END;
CREATE TRIGGER upd_hid_objCClassDefinition UPDATE OF hid ON headers BEGIN UPDATE objCClassDefinition SET hid = NEW.hid WHERE hid = OLD.hid; END;
CREATE TRIGGER upd_occlid_objCClassCategory UPDATE OF occlid ON objCClass BEGIN UPDATE objCClassCategory SET occlid = NEW.occlid WHERE occlid = OLD.occlid; END;
CREATE TRIGGER upd_occlid_objCClassDefinition UPDATE OF occlid ON objCClass BEGIN UPDATE objCClassDefinition SET occlid = NEW.occlid WHERE occlid = OLD.occlid; END;
CREATE TRIGGER upd_scclid_objCClassDefinition UPDATE OF occlid ON objCClass BEGIN UPDATE objCClassDefinition SET scclid = NEW.occlid WHERE scclid = OLD.occlid; END;
*/

CREATE VIEW v_tagid AS SELECT
hdc.hid AS hid,
hdc.hdcid AS hdcid,
t.position AS tpos,
tk.keyword AS keyword,
ta.argument AS arg,
ta.argText AS text
FROM
headerDocComments AS hdc
JOIN tags AS t ON hdc.hdcid = t.hdcid
JOIN tagKeywords AS tk ON t.tkid = tk.tkid
JOIN tagArguments AS ta ON ta.tid = t.tid;


CREATE VIEW v_objmtg AS SELECT
ocm.ocmid AS ocmid,
toc.tocid AS tocid,
tg.tgid AS tgid,
ocm.selector AS selector,
tg.groupName AS groupName,
v3.text AS abstract
FROM
objcMethods AS ocm
JOIN v_tagid AS v1 ON v1.keyword = 'method' AND v1.hdcid = ocm.hdcid
JOIN v_tagid AS v20 ON v20.keyword = 'tocgroup' AND v20.arg = 0 AND v20.hdcid = v1.hdcid
JOIN v_tagid AS v21 ON v21.keyword = 'tocgroup' AND v21.arg = 1 AND v21.hdcid = v1.hdcid
JOIN v_tagid AS v3 ON v3.keyword = 'abstract' AND v3.hdcid = v1.hdcid
JOIN toc ON toc.tocName = v20.text
JOIN tocGroup AS tg ON tg.groupName = v21.text
;



CREATE VIEW v_xaref_ocm AS SELECT
ocm.ocmid AS ocmid,
ocm.hdcid AS hdcid,
v0.keyword AS hdtype,
toc.tocName AS tocName,
tg.groupName AS groupName,
tm.pos AS pos,
toc.tocName || '.html' AS file,
occl.class || '_' || CASE WHEN ocm.type = '+' THEN '.' ELSE '-' END || ocm.selector AS linkId,
'//apple_ref/occ/' || CASE WHEN ocm.type = '+' THEN 'clm/' ELSE 'instm/' END || occl.class || '/' || ocm.selector AS apple_ref,
va.text AS titleText,
ocm.signature AS linkText
FROM
objCClassDefinition AS occldef
JOIN v_tagid AS v0 ON v0.hdcid = ocm.hdcid AND v0.tpos = 0
JOIN v_tagid AS va ON va.hdcid = ocm.hdcid AND va.keyword = 'abstract'
JOIN objCClass AS occl ON occl.occlid = occldef.occlid
JOIN objcMethods AS ocm ON ocm.hid = occldef.hid AND ocm.startsAt >= occldef.methodsStart AND ocm.startsAt <= (occldef.methodsStart + occldef.methodsLength)
JOIN toc ON toc.tocid = ocm.tocid
JOIN tocGroup AS tg ON tg.tgid = ocm.tgid
JOIN tocMembers AS tm ON tm.tocid = toc.tocid AND tm.tgid = tg.tgid
UNION
SELECT DISTINCT
ocm.ocmid AS ocmid,
ocm.hdcid AS hdcid,
'method' AS hdtype,
toc.tocName AS tocName,
tg.groupName AS groupName,
tm.pos AS pos,
toc.tocName || '.html' AS file,
occl.class || '_' || occlcat.category || '_' || '_' || CASE WHEN ocm.type = '+' THEN '.' ELSE '-' END  || ocm.selector AS linkId,
'//apple_ref/occ/' || CASE WHEN ocm.type = '+' THEN 'clm/' ELSE 'instm/' END || occl.class || '/' || ocm.selector AS apple_ref,
va.text AS titleText,
ocm.signature AS linkText
FROM
objCClassCategory AS occlcat
JOIN v_tagid AS va ON va.hdcid = ocm.hdcid AND va.keyword = 'abstract'
JOIN objCClass AS occl ON occl.occlid = occlcat.occlid
JOIN objcMethods AS ocm ON ocm.hid = occlcat.hid AND ocm.startsAt >= occlcat.methodsStart AND ocm.startsAt <= (occlcat.methodsStart + occlcat.methodsLength)
JOIN toc ON toc.tocid = ocm.tocid
JOIN tocGroup AS tg ON tg.tgid = ocm.tgid
JOIN tocMembers AS tm ON tm.tocid = toc.tocid AND tm.tgid = tg.tgid
;

CREATE VIEW v_xbref_ocm AS
SELECT ocm.ocmid AS ocmid, occl.class || '/' || ocm.type || ocm.selector AS xref FROM objCClassDefinition AS occldef
JOIN objCClass AS occl ON occl.occlid = occldef.occlid
JOIN objcMethods AS ocm ON ocm.hid = occldef.hid AND ocm.startsAt >= occldef.methodsStart AND ocm.startsAt <= (occldef.methodsStart + occldef.methodsLength) AND ocm.hdcid IS NOT NULL
UNION SELECT ocm.ocmid AS ocmid, occl.class || '/' || ocm.selector AS xref FROM objCClassDefinition AS occldef
JOIN objCClass AS occl ON occl.occlid = occldef.occlid
JOIN objcMethods AS ocm ON ocm.hid = occldef.hid AND ocm.startsAt >= occldef.methodsStart AND ocm.startsAt <= (occldef.methodsStart + occldef.methodsLength) AND ocm.hdcid IS NOT NULL
UNION SELECT ocm.ocmid AS ocmid, occl.class || '(' || occlcat.category || ')' || '/' || ocm.type || ocm.selector AS xref FROM objCClassCategory AS occlcat
JOIN objCClass AS occl ON occl.occlid = occlcat.occlid
JOIN objcMethods AS ocm ON ocm.hid = occlcat.hid AND ocm.startsAt >= occlcat.methodsStart AND ocm.startsAt <= (occlcat.methodsStart + occlcat.methodsLength) AND ocm.hdcid IS NOT NULL
UNION SELECT ocm.ocmid AS ocmid, occl.class || '(' || occlcat.category || ')' || '/' || ocm.selector AS xref FROM objCClassCategory AS occlcat
JOIN objCClass AS occl ON occl.occlid = occlcat.occlid
JOIN objcMethods AS ocm ON ocm.hid = occlcat.hid AND ocm.startsAt >= occlcat.methodsStart AND ocm.startsAt <= (occlcat.methodsStart + occlcat.methodsLength) AND ocm.hdcid IS NOT NULL
UNION SELECT ocm.ocmid AS ocmid, occl.class || '/' || ocm.type || ocm.selector AS xref FROM objCClassCategory AS occlcat
JOIN objCClass AS occl ON occl.occlid = occlcat.occlid
JOIN objcMethods AS ocm ON ocm.hid = occlcat.hid AND ocm.startsAt >= occlcat.methodsStart AND ocm.startsAt <= (occlcat.methodsStart + occlcat.methodsLength) AND ocm.hdcid IS NOT NULL
UNION SELECT ocm.ocmid AS ocmid, occl.class || '/' || ocm.selector AS xref FROM objCClassCategory AS occlcat
JOIN objCClass AS occl ON occl.occlid = occlcat.occlid
JOIN objcMethods AS ocm ON ocm.hid = occlcat.hid AND ocm.startsAt >= occlcat.methodsStart AND ocm.startsAt <= (occlcat.methodsStart + occlcat.methodsLength) AND ocm.hdcid IS NOT NULL
UNION SELECT ocm.ocmid AS ocmid, ocm.type || ' ' || ocm.selector AS xref FROM objcMethods AS ocm WHERE ocm.hdcid IS NOT NULL
UNION SELECT ocm.ocmid AS ocmid, ocm.type || ocm.selector AS xref FROM objcMethods AS ocm WHERE ocm.hdcid IS NOT NULL
UNION SELECT ocm.ocmid AS ocmid, ocm.selector AS xref FROM objcMethods AS ocm WHERE ocm.hdcid IS NOT NULL
UNION SELECT ocm.ocmid AS ocmid, ocm.signature AS xref FROM objcMethods AS ocm WHERE ocm.hdcid IS NOT NULL
UNION SELECT xa.ocmid AS ocmid, xa.apple_ref AS xref FROM v_xaref_ocm AS xa
;

CREATE VIEW v_xhref_ocm AS SELECT
'objCMethods' AS tbl,
'ocmid' AS idCol,
xa.ocmid AS id,
xa.hdcid AS hdcid,
xa.hdtype AS hdtype,
xb.xref AS xref,
xa.tocName AS tocName,
xa.groupName AS groupName,
xa.pos AS pos,
xa.file AS file,
xa.linkId AS linkId,
xa.apple_ref AS apple_ref,
xa.titleText AS titleText,
xa.linkText AS linkText
FROM v_xaref_ocm AS xa JOIN v_xbref_ocm AS xb ON xa.ocmid = xb.ocmid
;


CREATE VIEW v_xhref_const AS
SELECT
'constant' AS tbl,
'cid' AS idCol,
c.cid AS id,
c.hdcid AS hdcid,
'const' AS hdtype,
c.name AS xref,
toc.tocName AS tocName,
tg.groupName AS groupName,
tm.pos AS pos,
toc.tocName || '.html' AS file,
c.name AS linkId,
'//apple_ref/c/data/' || c.name AS apple_ref,
va.text AS titleText,
c.name AS linkText
FROM
constant AS c
JOIN v_tagid AS va ON va.hdcid = c.hdcid AND va.keyword = 'abstract'
JOIN v_tagid AS vt ON vt.hdcid = c.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0
JOIN v_tagid AS vg ON vg.hdcid = c.hdcid AND vg.keyword = 'tocgroup' AND vg.arg = 1
JOIN toc AS toc ON tocName = vt.text
JOIN tocGroup AS tg ON tg.groupName = vg.text
JOIN tocMembers AS tm ON tm.tocid = toc.tocid AND tm.tgid = tg.tgid
UNION
SELECT
'constant' AS tbl,
'cid' AS idCol,
c.cid AS id,
c.hdcid AS hdcid,
'const' AS hdtype,
c.name AS xref,
'Constants' AS tocName,
NULL AS groupName,
tm.pos AS pos,
'Constants.html' AS file,
c.name AS linkId,
'//apple_ref/c/data/' || c.name AS apple_ref,
va.text AS titleText,
c.name AS linkText
FROM
constant AS c
JOIN v_tagid AS va ON va.hdcid = c.hdcid AND va.keyword = 'abstract',
(SELECT coalesce(max(tm.pos)+1, 1) AS pos
FROM tocMembers AS tm
JOIN toc ON toc.tocid = tm.tocid AND toc.tocName = 'Constants'
JOIN tocGroup AS tg ON tg.tgid = tm.tgid) AS tm
WHERE (SELECT vt.hdcid FROM v_tagid AS vt WHERE vt.hdcid = c.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0 LIMIT 1) IS NULL 
;

CREATE VIEW v_xhref_define AS
SELECT
'define' AS tbl,
'did' AS idCol,
d.did AS id,
d.hdcid AS hdcid,
'defined' AS hdtype,
d.defineName AS xref,
toc.tocName AS tocName,
tg.groupName AS groupName,
tm.pos AS pos,
toc.tocName || '.html' AS file,
d.defineName AS linkId,
'//apple_ref/c/macro/' || d.defineName AS apple_ref,
va.text AS titleText,
d.defineName AS linkText
FROM
(SELECT * FROM define WHERE hdcid IS NOT NULL) AS d
--JOIN v_tagid AS vd ON vd.keyword = 'defined' AND vd.text = d.defineName
JOIN v_tagid AS va ON va.hdcid = d.hdcid AND va.keyword = 'abstract'
JOIN v_tagid AS vt ON vt.hdcid = d.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0
JOIN v_tagid AS vg ON vg.hdcid = d.hdcid AND vg.keyword = 'tocgroup' AND vg.arg = 1
JOIN toc AS toc ON tocName = vt.text
JOIN tocGroup AS tg ON tg.groupName = vg.text
JOIN tocMembers AS tm ON tm.tocid = toc.tocid AND tm.tgid = tg.tgid
UNION
SELECT
'define' AS tbl,
'did' AS idCol,
d.did AS id,
d.hdcid AS hdcid,
'defined' AS hdtype,
d.defineName AS xref,
'Constants' AS tocName,
'Constants' AS groupName,
tm.pos AS pos,
'Constants.html' AS file,
d.defineName AS linkId,
'//apple_ref/c/macro/' || d.defineName AS apple_ref,
va.text AS titleText,
d.defineName AS linkText
FROM
(SELECT * FROM define WHERE hdcid IS NOT NULL) AS d
--JOIN v_tagid AS vd ON vd.keyword = 'defined' AND vd.text = d.defineName
JOIN v_tagid AS va ON va.hdcid = d.hdcid AND va.keyword = 'abstract',
(SELECT coalesce(max(tm.pos)+1, 1) AS pos
FROM tocMembers AS tm
JOIN toc ON toc.tocid = tm.tocid AND toc.tocName = 'Constants'
JOIN tocGroup AS tg ON tg.tgid = tm.tgid) AS tm
WHERE (SELECT vt.hdcid FROM v_tagid AS vt WHERE vt.hdcid = d.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0 LIMIT 1) IS NULL 
;



CREATE VIEW v_xhref_typedef AS
SELECT
'typedefEnum' AS tbl,
'tdeid' AS idCol,
td.tdeid AS id,
td.hdcid AS hdcid,
'typedef' AS hdtype,
td.name AS xref,
toc.tocName AS tocName,
tg.groupName AS groupName,
tm.pos AS pos,
toc.tocName || '.html' AS file,
td.name AS linkId,
'//apple_ref/c/tdef/' || td.name AS apple_ref,
va.text AS titleText,
td.name AS linkText
FROM
typedefEnum AS td
JOIN v_tagid AS va ON va.hdcid = td.hdcid AND va.keyword = 'abstract'
JOIN v_tagid AS vt ON vt.hdcid = td.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0
JOIN v_tagid AS vg ON vg.hdcid = td.hdcid AND vg.keyword = 'tocgroup' AND vg.arg = 1
JOIN toc AS toc ON tocName = vt.text
JOIN tocGroup AS tg ON tg.groupName = vg.text
JOIN tocMembers AS tm ON tm.tocid = toc.tocid AND tm.tgid = tg.tgid
UNION
SELECT 
'typedefEnum' AS tbl,
'tdeid' AS idCol,
td.tdeid AS id,
td.hdcid AS hdcid,
'typedef' AS hdtype,
td.name AS xref,
'DataTypes' AS tocName,
NULL AS groupName,
tm.pos AS pos,
'DataTypes.html' AS file,
td.name AS linkId,
'//apple_ref/c/tdef/' || td.name AS apple_ref,
va.text AS titleText,
td.name AS linkText
FROM
typedefEnum AS td
JOIN v_tagid AS va ON va.hdcid = td.hdcid AND va.keyword = 'abstract',
(SELECT coalesce(max(tm.pos)+1, 1) AS pos
FROM tocMembers AS tm
JOIN toc ON toc.tocid = tm.tocid AND toc.tocName = 'DataTypes'
JOIN tocGroup AS tg ON tg.tgid = tm.tgid) AS tm
WHERE (SELECT vt.hdcid FROM v_tagid AS vt WHERE vt.hdcid = td.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0 LIMIT 1) IS NULL 
;

CREATE VIEW v_xhref_typedef_enum AS
SELECT
'enumIdentifier' AS tbl,
'eid' AS idCol,
ei.eid AS id,
td.hdcid AS hdcid,
'constant' AS hdtype,
td.name || '/' || ei.identifier AS xref,
NULL AS tocName,
NULL AS groupName,
NULL AS pos,
toc.tocName || '.html' AS file,
td.name || '_' || ei.identifier AS linkId,
'//apple_ref/c/econst/' || ei.identifier AS apple_ref,
NULL AS titleText,
NULL AS linkText
FROM
typedefEnum AS td
JOIN enumIdentifier AS ei ON ei.tdeid = td.tdeid
JOIN v_tagid AS vt ON vt.hdcid = td.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0
JOIN v_tagid AS vg ON vg.hdcid = td.hdcid AND vg.keyword = 'tocgroup' AND vg.arg = 1
JOIN toc AS toc ON tocName = vt.text
JOIN tocGroup AS tg ON tg.groupName = vg.text

UNION

SELECT 
'enumIdentifier' AS tbl,
'eid' AS idCol,
ei.eid AS id,
td.hdcid AS hdcid,
'constant' AS hdtype,
td.name || '/' || ei.identifier AS xref,
NULL AS tocName,
NULL AS groupName,
NULL AS pos,
'DataTypes.html' AS file,
td.name || '_' || ei.identifier AS linkId,
'//apple_ref/c/econst/' || ei.identifier AS apple_ref,
NULL AS titleText,
NULL AS linkText
FROM typedefEnum AS td JOIN enumIdentifier AS ei ON ei.tdeid = td.tdeid
WHERE (SELECT vt.hdcid FROM v_tagid AS vt WHERE vt.hdcid = td.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0 LIMIT 1) IS NULL 

UNION

SELECT
'enumIdentifier' AS tbl,
'eid' AS idCol,
ei.eid AS id,
td.hdcid AS hdcid,
'constant' AS hdtype,
ei.identifier AS xref,
NULL AS tocName,
NULL AS groupName,
NULL AS pos,
toc.tocName || '.html' AS file,
td.name || '_' || ei.identifier AS linkId,
'//apple_ref/c/econst/' || ei.identifier AS apple_ref,
NULL AS titleText,
NULL AS linkText
FROM
typedefEnum AS td
JOIN enumIdentifier AS ei ON ei.tdeid = td.tdeid
JOIN v_tagid AS vt ON vt.hdcid = td.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0
JOIN v_tagid AS vg ON vg.hdcid = td.hdcid AND vg.keyword = 'tocgroup' AND vg.arg = 1
JOIN toc AS toc ON tocName = vt.text
JOIN tocGroup AS tg ON tg.groupName = vg.text

UNION

SELECT
'enumIdentifier' AS tbl,
'eid' AS idCol,
ei.eid AS id,
td.hdcid AS hdcid,
'constant' AS hdtype,
ei.identifier AS xref,
NULL AS tocName,
NULL AS groupName,
NULL AS pos,
'DataTypes.html' AS file,
td.name || '_' || ei.identifier AS linkId,
'//apple_ref/c/econst/' || ei.identifier AS apple_ref,
NULL AS titleText,
NULL AS linkText
FROM typedefEnum AS td JOIN enumIdentifier AS ei ON ei.tdeid = td.tdeid
WHERE (SELECT vt.hdcid FROM v_tagid AS vt WHERE vt.hdcid = td.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0 LIMIT 1) IS NULL 
;

CREATE VIEW v_xhref_func AS
SELECT
'prototypes' AS tbl,
'pid' AS idCol,
p.pid AS id,
p.hdcid AS hdcid,
'function' AS hdtype,
p.sym AS xref,
toc.tocName AS tocName,
tg.groupName AS groupName,
tm.pos AS pos,
toc.tocName || '.html' AS file,
p.sym AS linkId,
'//apple_ref/c/func/' || p.sym AS apple_ref,
va.text AS titleText,
p.sym AS linkText
FROM
(SELECT * FROM prototypes WHERE hdcid IS NOT NULL) AS p
JOIN v_tagid AS va ON va.hdcid = p.hdcid AND va.keyword = 'abstract'
JOIN v_tagid AS vt ON vt.hdcid = p.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0
JOIN v_tagid AS vg ON vg.hdcid = p.hdcid AND vg.keyword = 'tocgroup' AND vg.arg = 1
JOIN toc AS toc ON tocName = vt.text
JOIN tocGroup AS tg ON tg.groupName = vg.text
JOIN tocMembers AS tm ON tm.tocid = toc.tocid AND tm.tgid = tg.tgid
UNION
SELECT
'prototypes' AS tbl,
'pid' AS idCol,
p.pid AS id,
p.hdcid AS hdcid,
'function' AS hdtype,
p.sym AS xref,
'Functions' AS tocName,
NULL AS groupName,
tm.pos AS pos,
'Functions.html' AS file,
p.sym AS linkId,
'//apple_ref/c/func/' || p.sym AS apple_ref,
va.text AS titleText,
p.sym AS linkText
FROM
(SELECT * FROM prototypes WHERE hdcid IS NOT NULL) AS p
JOIN v_tagid AS va ON va.hdcid = p.hdcid AND va.keyword = 'abstract',
(SELECT coalesce(max(tm.pos)+1, 1) AS pos
FROM tocMembers AS tm
JOIN toc ON toc.tocid = tm.tocid AND toc.tocName = 'Functions'
JOIN tocGroup AS tg ON tg.tgid = tm.tgid) AS tm
WHERE (SELECT vt.hdcid FROM v_tagid AS vt WHERE vt.hdcid = p.hdcid AND vt.keyword = 'tocgroup' AND vt.arg = 0 LIMIT 1) IS NULL 
;

CREATE VIEW v_xhref_class AS SELECT
'objCClass' AS tbl,
'occlid' AS idCol,
occl.occlid AS id,
v1.hdcid AS hdcid,
'class' AS hdtype,
occl.class AS xref,
toc.tocName AS tocName,
NULL AS groupName,
NULL AS pos,
v2.text || '.html' AS file,
NULL AS linkId,
'//apple_ref/occ/cl/' || occl.class AS apple_ref,
va.text AS titleText,
occl.class AS linkText
FROM objcclass AS occl
JOIN v_tagid AS v1 ON v1.keyword = 'class' AND v1.text = occl.class 
JOIN v_tagid AS v2 ON v2.hdcid = v1.hdcid AND v2.keyword = 'toc'
JOIN toc ON toc.tocName = v2.text
JOIN v_tagid AS va ON va.hdcid = v1.hdcid AND va.keyword = 'abstract'
;


CREATE VIEW v_xxref AS 
      SELECT xref, coalesce(linkId, ""), coalesce(file || '#' || coalesce(linkId, ""), file) AS href FROM v_xhref_const 
UNION SELECT xref, coalesce(linkId, ""), coalesce(file || '#' || coalesce(linkId, ""), file) AS href FROM v_xhref_ocm
UNION SELECT xref, coalesce(linkId, ""), coalesce(file || '#' || coalesce(linkId, ""), file) AS href FROM v_xhref_typedef
UNION SELECT xref, coalesce(linkId, ""), coalesce(file || '#' || coalesce(linkId, ""), file) AS href FROM v_xhref_typedef_enum
UNION SELECT xref, coalesce(linkId, ""), coalesce(file || '#' || coalesce(linkId, ""), file) AS href FROM v_xhref_func
UNION SELECT xref, coalesce(linkId, ""), coalesce(file || '#' || coalesce(linkId, ""), file) AS href FROM v_xhref_class
;

CREATE VIEW v_xxapple_ref AS 
      SELECT xref, coalesce(apple_ref, ""), coalesce(file || '#' || coalesce(apple_ref, ""), file) AS href FROM v_xhref_const 
UNION SELECT xref, coalesce(apple_ref, ""), coalesce(file || '#' || coalesce(apple_ref, ""), file) AS href FROM v_xhref_ocm
UNION SELECT xref, coalesce(apple_ref, ""), coalesce(file || '#' || coalesce(apple_ref, ""), file) AS href FROM v_xhref_typedef
UNION SELECT xref, coalesce(apple_ref, ""), coalesce(file || '#' || coalesce(apple_ref, ""), file) AS href FROM v_xhref_typedef_enum
UNION SELECT xref, coalesce(apple_ref, ""), coalesce(file || '#' || coalesce(apple_ref, ""), file) AS href FROM v_xhref_func
UNION SELECT xref, coalesce(apple_ref, ""), coalesce(file || '#' || coalesce(apple_ref, ""), file) AS href FROM v_xhref_class
;

CREATE VIEW v_xtoc AS 
      SELECT tbl, idCol, id, hdcid, hdtype, xref, tocName, groupName, pos, file, coalesce(linkId, "") AS linkId, coalesce(file || '#' || linkId, file) AS href, coalesce(apple_ref, "") AS apple_ref, titleText, linkText FROM v_xhref_const 
UNION SELECT tbl, idCol, id, hdcid, hdtype, xref, tocName, groupName, pos, file, coalesce(linkId, "") AS linkId, coalesce(file || '#' || linkId, file) AS href, coalesce(apple_ref, "") AS apple_ref, titleText, linkText FROM v_xhref_ocm
UNION SELECT tbl, idCol, id, hdcid, hdtype, xref, tocName, groupName, pos, file, coalesce(linkId, "") AS linkId, coalesce(file || '#' || linkId, file) AS href, coalesce(apple_ref, "") AS apple_ref, titleText, linkText FROM v_xhref_typedef
UNION SELECT tbl, idCol, id, hdcid, hdtype, xref, NULL,    NULL,      pos, file, coalesce(linkId, "") AS linkId, coalesce(file || '#' || linkId, file) AS href, coalesce(apple_ref, "") AS apple_ref, NULL,      NULL     FROM v_xhref_typedef_enum
UNION SELECT tbl, idCol, id, hdcid, hdtype, xref, tocName, groupName, pos, file, coalesce(linkId, "") AS linkId, coalesce(file || '#' || linkId, file) AS href, coalesce(apple_ref, "") AS apple_ref, titleText, linkText FROM v_xhref_func
UNION SELECT tbl, idCol, id, hdcid, hdtype, xref, tocName, groupName, pos, file, coalesce(linkId, "") AS linkId, coalesce(file || '#' || linkId, file) AS href, coalesce(apple_ref, "") AS apple_ref, titleText, linkText FROM v_xhref_class
UNION SELECT tbl, idCol, id, hdcid, hdtype, xref, tocName, groupName, pos, file, coalesce(linkId, "") AS linkId, coalesce(file || '#' || linkId, file) AS href, coalesce(apple_ref, "") AS apple_ref, titleText, linkText FROM v_xhref_define
;


CREATE VIEW v_hd_tags AS
SELECT
hdc.hid AS hid,
hdc.hdcid AS hdcid,
tk.multiple AS multiple,
t.position AS tpos,
tk.keyword AS keyword,
ta0.argText AS arg0,
NULL AS arg1
FROM
headerDocComments AS hdc
JOIN tags AS t ON hdc.hdcid = t.hdcid
JOIN tagKeywords AS tk ON t.tkid = tk.tkid AND tk.arguments = 1
JOIN tagArguments AS ta0 ON ta0.tid = t.tid AND ta0.argument = 0
UNION
SELECT
hdc.hid AS hid,
hdc.hdcid AS hdcid,
tk.multiple AS multiple,
t.position AS tpos,
tk.keyword AS keyword,
ta0.argText AS arg0,
ta1.argText AS arg1
FROM
headerDocComments AS hdc
JOIN tags AS t ON hdc.hdcid = t.hdcid
JOIN tagKeywords AS tk ON t.tkid = tk.tkid AND tk.arguments = 2
JOIN tagArguments AS ta0 ON ta0.tid = t.tid AND ta0.argument = 0
JOIN tagArguments AS ta1 ON ta1.tid = t.tid AND ta1.argument = 1
;


CREATE VIEW v_occlid_ocmid_map AS
SELECT
occl.occlid AS occlid,
ocm.ocmid AS ocmid
FROM
objCClassDefinition AS occldef
JOIN objCClass AS occl ON occl.occlid = occldef.occlid
JOIN objcMethods AS ocm ON ocm.hid = occldef.hid AND ocm.startsAt >= occldef.methodsStart AND ocm.startsAt <= (occldef.methodsStart + occldef.methodsLength)
UNION
SELECT
occl.occlid AS occlid,
ocm.ocmid AS ocmid
FROM
objCClassCategory AS occlcat
JOIN objCClass AS occl ON occl.occlid = occlcat.occlid
JOIN objcMethods AS ocm ON ocm.hid = occlcat.hid AND ocm.startsAt >= occlcat.methodsStart AND ocm.startsAt <= (occlcat.methodsStart + occlcat.methodsLength)
;

CREATE VIEW tableOfContents AS
SELECT
toc.tocid AS tocid,
tg.tgid AS tgid,
toc.tocName AS tocName,
tg.groupName AS groupName,
tm.pos AS pos
FROM
tocMembers AS tm
JOIN toc ON toc.tocid = tm.tocid
JOIN tocGroup AS tg ON tg.tgid = tm.tgid
;

CREATE INDEX objCMethods_occlid_idx ON objCMethods (occlid);
CREATE INDEX define_hdcid_idx ON define (hdcid);


CREATE TABLE docset (
dsid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
docset TEXT NOT NULL,
UNIQUE (docset) ON CONFLICT REPLACE
);

CREATE TABLE files (
fid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
dsid INTEGER,
path TEXT NOT NULL,
file TEXT NOT NULL,
filePath TEXT NOT NULL,
UNIQUE (path, file) ON CONFLICT IGNORE
);

CREATE INDEX files_dsid_path_file_idx ON files (dsid, path, file);
CREATE INDEX files_filePath_idx ON files (filePath);

CREATE TABLE nodeNames (
refid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
fid INTEGER NOT NULL,
anchor TEXT,
href TEXT NOT NULL,
name TEXT NOT NULL,
UNIQUE (refid, anchor) ON CONFLICT REPLACE
);

CREATE INDEX nodeNames_fid ON nodeNames (fid);

CREATE TRIGGER nodeNames_null_anchor_trig
AFTER INSERT ON nodeNames
FOR EACH ROW WHEN NEW.anchor IS NULL
BEGIN DELETE FROM nodeNames WHERE nodeNames.anchor IS NULL AND nodeNames.fid = NEW.fid AND refid != NEW.refid; END;


COMMIT;
