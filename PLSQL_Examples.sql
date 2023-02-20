-- Formulati în  limbaj  natural o problema pe care sa o rezolvati folosind un subprogram stocat independent care sa utilizeze doua tipuri diferite de colectii studiate. Apelati subprogramul.

-- Cerinta:  Sa se defineasca un subprogram stocat independent care afiseaza numele si prenumele antrenorilor precum si campionatul in care joaca echipa la care acestia antreneaza, 
-- campionatul respectiv avand tipul de desfasurare  "play".

CREATE OR REPLACE PROCEDURE p6_SelectareAntrenori IS
    TYPE vector_antrenori IS VARRAY(50) OF
        antrenor%ROWTYPE;
        v_antr vector_antrenori;
        
    TYPE campionate IS TABLE OF
        campionat_intern%ROWTYPE
        INDEX BY PLS_INTEGER;
        v_camp campionate;
    
    id_camp_echipa NUMBER(2);
    
BEGIN
    SELECT antrenor.*
    BULK COLLECT INTO v_antr
    FROM antrenor;
    
    SELECT campionat_intern.*
    BULK COLLECT INTO v_camp
    FROM campionat_intern
    WHERE mod_desfasurare = 'play';
    
    FOR ind IN v_antr.FIRST..v_antr.LAST LOOP
        SELECT id_campionat INTO id_camp_echipa
        FROM echipa 
        WHERE id_echipa = v_antr(ind).id_echipa;
        FOR jnd IN v_camp.FIRST..v_camp.LAST LOOP
            IF id_camp_echipa = v_camp(jnd).id_campionat THEN
                DBMS_OUTPUT.PUT_LINE(v_antr(ind).nume || ' ' || v_antr(ind).prenume || '       ' || v_camp(jnd).nume);
            END IF;
        END LOOP;
    END LOOP;
    
    EXCEPTION WHEN no_data_found THEN
        raise_application_error(-20000, 'Nu exista antrenori care sa antreneze la echipe care joaca intr-un campionat cu acest tip de desfasurare');
END;
/

exec p6_SelectareAntrenori;


-- 7.

-- Formulati în limbaj natural o problema pe care sa o rezolvati folosind un subprogram stocat independent care sa utilizeze 2 tipuri diferite de cursoare studiate,
-- unul dintre acestea fiind cursor parametrizat. Apelati subprogramul.

-- Cerinta: Sa se defineasca un subprogram stocat independent care sa afiseze pentru un meci al carui data este dat ca parametru numele antrenorului care antreneaza echipa care joaca in acel 
--                meci si care are cea mai mica medie de varsta a jucatorilor din componenta.

CREATE OR REPLACE PROCEDURE p7_AntrenoriVarsta(data_introdusa meci.data%TYPE) IS
    CURSOR meciuri(meci_data meci.data%TYPE) IS
        SELECT m.id_meci, m.data,
            CURSOR (
                SELECT a.nume, a.prenume
                FROM antrenor a, echipa e, jucator j
                WHERE e.id_echipa = a.id_echipa 
                AND j.id_echipa = e.id_echipa 
                AND (e.id_echipa = jo.id_echipa1 OR e.id_echipa = jo.id_echipa2)
                HAVING avg(j.varsta) = (SELECT MIN(AVG(j.varsta))
                                                             FROM antrenor a, echipa e, jucator j
                                                            WHERE e.id_echipa = a.id_echipa AND j.id_echipa = e.id_echipa AND (e.id_echipa = jo.id_echipa1 OR e.id_echipa = jo.id_echipa2)
                                                            GROUP BY e.id_echipa)
                GROUP BY a.nume, a.prenume)
        FROM meci m, joaca jo
        WHERE m.data = meci_data AND m.id_meci = jo.id_meci;
        
    TYPE antrenori IS REF CURSOR;
    v_antrenori antrenori;
    v_data meci.data%TYPE;
    v_id_meci meci.id_meci%TYPE;
    v_nume_antrenor antrenor.nume%TYPE;
    v_prenume_antrenor antrenor.prenume%TYPE;

BEGIN
    OPEN meciuri(data_introdusa);
    LOOP
        FETCH meciuri into v_id_meci, v_data, v_antrenori;
        EXIT WHEN meciuri%NOTFOUND;
        
        LOOP
            FETCH v_antrenori into v_nume_antrenor, v_prenume_antrenor;
            EXIT WHEN v_antrenori%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Antrenor:' || ' ' || v_nume_antrenor || ' ' || v_prenume_antrenor);
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('---------------------------');
        
    END LOOP;
    CLOSE meciuri;
        
END;
/
        
exec p7_AntrenoriVarsta('18-APR-22');


-- 8.

-- Formulati în limbaj natural o problema pe care sa o rezolvati folosind un subprogram stocat independent de tip functie care sa utilizeze într-o singura comanda SQL 3 dintre tabelele definite. 
-- Definiti minim 2 exceptii. Apelati subprogramul astfel încât sa evidentiati toate cazurile tratate

-- Cerinta: Sa se defineasca o functie care sa afiseze numele stadionului pe care joaca echipa care este sponsorizata de un sponsor al carui nume este dat ca parametru.

CREATE OR REPLACE FUNCTION p8_AfisareStadion(nume_sponsor sponsor.nume%TYPE)
    RETURN VARCHAR2 IS
    v_rezultat VARCHAR2(20);
    v_sponsor sponsor.nume%TYPE := nume_sponsor;
    v_sponsor_tabel NUMBER := 0;
    
BEGIN
    SELECT count(*) INTO v_sponsor_tabel
    FROM sponsor
    WHERE lower(nume) = lower(nume_sponsor);
    
    IF v_sponsor_tabel = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nu exista sponsorul dat ca parametru!');
    END IF;
    
    SELECT s.nume INTO v_rezultat
    FROM stadion s, sponsor sp, echipa e
    WHERE e.id_stadion = s.id_stadion AND e.id_echipa = sp.id_echipa and lower(sp.nume) = lower(nume_sponsor);
    
    RETURN v_rezultat;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Sponsorul dat ca parametru nu sponsorizeaza nicio echipa!');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Prea multe date');
    
END p8_AfisareStadion;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Rezultatul este: ' || p8_AfisareStadion('City Insurance'));
END;
/


-- 9.

-- Formulati în limbaj natural o problema pe care sa o rezolvati folosind un subprogram stocat independent de tip procedura care sa utilizeze într-o singura comanda SQL 5 dintre tabelele 
-- definite. Tratati toate exceptiile care pot ap?rea, incluzând exceptiile NO_DATA_FOUND si TOO_MANY_ROWS. Apelati subprogramul astfel încât s? evidentiati toate cazurile tratate.

-- Cerinta: Sa se defineasca o procedura care sa afiseze numele nationalei care s-a calificat la campionatul european si la care joaca cel mai varstnic jucator care joaca pe postul dat ca parametru 
--               al uneia dintre echipe care joaca in meciul al carui id este dat ca parametru., alaturi de numele, prenumele, numarul de pe tricou si varsta jucatorului.       

CREATE OR REPLACE PROCEDURE p9_AfisareNationala(param_id_meci meci.id_meci%TYPE, param_post jucator.post%TYPE) IS
    v_nationala_nume nationala.nume%TYPE;
    v_jucator_nume jucator.nume%TYPE;
    v_jucator_prenume jucator.prenume%TYPE;
    v_jucator_numar jucator.numar%TYPE;
    v_jucator_varsta jucator.varsta%TYPE;
    v_meci_tabel NUMBER(2) := 0;
    v_post_tabel NUMBER(2) := 0;
    v_post_echipe NUMBER(2) := 0;

BEGIN
    SELECT COUNT(*) INTO v_meci_tabel
    FROM meci
    WHERE id_meci = param_id_meci;
    
    IF v_meci_tabel = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nu exista niciun meci cu id-ul dat ca parametru!');    
    END IF;
    
    SELECT COUNT(*) INTO v_post_tabel
    FROM jucator
    WHERE post = param_post;
    
    IF v_post_tabel = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nu exista niciun post cu denumirea postului dat ca parametru!');
    END IF;
        
    SELECT COUNT(*) into v_post_echipe
    FROM echipa e, meci m, joaca j, jucator ju
    WHERE m.id_meci = j.id_meci
    AND (e.id_echipa = j.id_echipa1 OR e.id_echipa = j.id_echipa2)
    AND ju.id_echipa = e.id_echipa 
    AND m.id_meci = param_id_meci  
    AND ju.post = param_post;
    
    IF v_post_echipe = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nu exista niciun jucator care sa joace pe postul dat ca parametru in una din cele 2 echipa care joaca in meciul dat ca parametru!');
    END IF;
    
    SELECT n.nume, ju.nume, ju.prenume, ju.numar, ju.varsta INTO v_nationala_nume, v_jucator_nume, v_jucator_prenume, v_jucator_numar, v_jucator_varsta
    FROM nationala n, joaca j, echipa e, jucator ju, meci m
    WHERE ju.id_nationala = n.id_nationala 
    AND ju.id_echipa = e.id_echipa 
    AND (e.id_echipa = j.id_echipa1 OR e.id_echipa = j.id_echipa2) 
    AND j.id_meci = m.id_meci 
    AND m.id_meci = param_id_meci 
    AND ju.post = param_post
    AND id_nationale IS NOT NULL
    AND ju.varsta = (SELECT MAX(ju.varsta)
                                 FROM nationala n, joaca j, echipa e, jucator ju, meci m
                                 WHERE ju.id_nationala = n.id_nationala 
                                 AND ju.id_echipa = e.id_echipa 
                                 AND (e.id_echipa = j.id_echipa1 OR e.id_echipa = j.id_echipa2) 
                                 AND j.id_meci = m.id_meci 
                                 AND m.id_meci = param_id_meci 
                                 AND ju.post = param_post
                                 AND id_nationale IS NOT NULL);
                                 
    DBMS_OUTPUT.PUT_LINE('Nationala: ' ||  v_nationala_nume);
    DBMS_OUTPUT.PUT_LINE('Nume: '  || v_jucator_nume);
    DBMS_OUTPUT.PUT_LINE('Prenume: ' || v_jucator_prenume);
    DBMS_OUTPUT.PUT_LINE('Numar: ' || v_jucator_numar);
    DBMS_OUTPUT.PUT_LINE( 'Varsta: ' || v_jucator_varsta);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'Jucatorul nu apartine de o nationala calificata la campionatul euroean!');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20005, 'Exista mai mult de 1 jucator cu varsta maxima intr-o nationala calificata la campionatul european.');
        
END;
/

exec p9_AfisareNationala(216, 'fundas');

-- 10.

-- Definiti un trigger de tip LMD la nivel de comand?. Declansati trigger-ul

-- Cerinta: Sa se defineasca un trigger care permite adaugare unei noi linii in tabela SPONSOR doar in intervalul orar 9-16 si numai atunci cand restul de sponsori care sunt adaugati in acea tabela
--               sunt asociati cu o echipa. Doar utilizatorul mentionat are voie sa adauge un sponsor.

CREATE OR REPLACE TRIGGER ex10_trigger 
    BEFORE INSERT ON sponsor

DECLARE
    v_utilizator VARCHAR2(30);
    v_numar1 NUMBER(2);
    v_numar2 NUMBER(2);

BEGIN
    IF (TO_CHAR(SYSDATE, 'hh24') NOT BETWEEN 9 AND 16) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nu se pot efectua modificari in afara orelor specificate!');
    END IF;
    
    SELECT lower(user) INTO v_utilizator FROM dual;
    IF v_utilizator != lower('Valentin') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Doar utilizatorul mentionat are dreptul de a efectua modificari la nivelul bazei de date!');
    END IF;
    
    SELECT COUNT(*) INTO v_numar1
    FROM sponsor;
    
    SELECT COUNT(*) INTO v_numar2
    FROM sponsor
    WHERE id_echipa IS NOT NULL;
    
    IF v_numar1 != v_numar2 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nu este permisa introducerea unui nou sponsor pana cand ultimul sponsor adaugat nu se asociaza cu o echipa!');
    END IF;
END;
/

-- Declansare trigger.
insert into SPONSOR (id_sponsor, id_echipa, nume)
values(26, null, 'Adidas');

drop trigger ex10_trigger;

-- 11.

-- Definiti un trigger de tip LMD la nivel de linie. Declansati trigger-ul.

-- Cerinta: Sa se creeze un trigger de tip LMD la nivel de linie prin care sa poata fi exclusi de la echipa nationala doar jucatorii ale caror echipe la care joaca
--               nu participa la niciun campionat european pentru cluburi.

CREATE OR REPLACE TRIGGER ex11_trigger
    BEFORE UPDATE OF id_nationala ON  jucator
    FOR EACH ROW
DECLARE
    v_echipa_jucator echipa.id_echipa%TYPE;
    v_id_jucator jucator.id_jucator%TYPE;
    v_echipa_participa NUMBER := 0;
    
BEGIN
    
    IF  :NEW.id_nationala is null THEN
    
        SELECT id_echipa INTO v_echipa_jucator
        FROM echipa
        WHERE id_echipa = :OLD.id_echipa;
    
        SELECT COUNT(*) INTO v_echipa_participa
        FROM participa
        WHERE id_echipa  = v_echipa_jucator;
        
        IF v_echipa_participa > 0 THEN
            dbms_output.put_line('Calificare: ' || v_echipa_participa);
            RAISE_APPLICATION_ERROR(-20001, 'Jucatorul nu poate fi exclus din lotul echipei nationale deoarece echipa la care joaca este calificata la un turneu european!');
        END IF;
    END IF;
        
    IF :OLD.id_nationala IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Jucatorul nu este convocat la nationala!');
    END IF;
        
END;
/

-- Declansare trigger.
UPDATE jucator SET id_nationala = null
WHERE id_jucator = 381;

drop trigger ex11_trigger;

-- 12.

-- Definiti un trigger de tip LDD. Declansati trigger-ul.

-- Definiti un trigger de tip LDD care sa permita modificarea tabelelor doar de catre utilizatorul Valentin. Sa se salveze toate modificarile facute intr-o tabela noua.

CREATE TABLE comenzi_istoric (
    user_logat VARCHAR2(30),
    event VARCHAR2(20),
    nume_baza VARCHAR2(30),
    obiect VARCHAR2(100),
    data_mod DATE
);

CREATE OR REPLACE TRIGGER ex12_trigger 
    BEFORE CREATE OR ALTER OR DROP ON SCHEMA
BEGIN
    IF USER != UPPER('Valentin') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nu aveti dreptul de a face modificari!');
    END IF;
    INSERT INTO comenzi_istoric VALUES(SYS.LOGIN_USER, SYS.SYSEVENT, SYS.DATABASE_NAME, SYS.DICTIONARY_OBJ_NAME, SYSTIMESTAMP(3));
END;
/

-- Declansare trigger

ALTER TABLE sponsor ADD promovare VARCHAR2(30);
ALTER TABLE sponsor DROP COLUMN promovare;


-- 13. Definiti un pachet care sa contina toate obiectele definite în cadrul proiectului.

CREATE OR REPLACE PACKAGE ex13_PachetProiect AS
    PROCEDURE p6_SelectareAntrenori;
    PROCEDURE p7_AntrenoriVarsta(data_introdusa meci.data%TYPE);
    FUNCTION p8_AfisareStadion(nume_sponsor sponsor.nume%TYPE) RETURN VARCHAR2;
    PROCEDURE p9_AfisareNationala(param_id_meci meci.id_meci%TYPE, param_post jucator.post%TYPE);
END ex13_PachetProiect;
/

CREATE OR REPLACE PACKAGE BODY ex13_PachetProiect AS

-- 6. ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
    PROCEDURE p6_SelectareAntrenori IS
        TYPE vector_antrenori IS VARRAY(50) OF
            antrenor%ROWTYPE;
            v_antr vector_antrenori;
            
        TYPE campionate IS TABLE OF
            campionat_intern%ROWTYPE
            INDEX BY PLS_INTEGER;
            v_camp campionate;
        
        id_camp_echipa NUMBER(2);
    
    BEGIN
        SELECT antrenor.*
        BULK COLLECT INTO v_antr
        FROM antrenor;
        
        SELECT campionat_intern.*
        BULK COLLECT INTO v_camp
        FROM campionat_intern
        WHERE mod_desfasurare = 'play';
        
        FOR ind IN v_antr.FIRST..v_antr.LAST LOOP
            SELECT id_campionat INTO id_camp_echipa
            FROM echipa 
            WHERE id_echipa = v_antr(ind).id_echipa;
            FOR jnd IN v_camp.FIRST..v_camp.LAST LOOP
                IF id_camp_echipa = v_camp(jnd).id_campionat THEN
                    DBMS_OUTPUT.PUT_LINE(v_antr(ind).nume || ' ' || v_antr(ind).prenume || '       ' || v_camp(jnd).nume);
                END IF;
            END LOOP;
        END LOOP;
        
        EXCEPTION WHEN no_data_found THEN
            raise_application_error(-20000, 'Nu exista antrenori care sa antreneze la echipe care joaca intr-un campionat cu acest tip de desfasurare');
    END p6_SelectareAntrenori;
 
 -- 7. ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    PROCEDURE p7_AntrenoriVarsta(data_introdusa meci.data%TYPE) IS
        CURSOR meciuri(meci_data meci.data%TYPE) IS
            SELECT m.id_meci, m.data,
                CURSOR (
                    SELECT a.nume, a.prenume
                    FROM antrenor a, echipa e, jucator j
                    WHERE e.id_echipa = a.id_echipa 
                    AND j.id_echipa = e.id_echipa 
                    AND (e.id_echipa = jo.id_echipa1 OR e.id_echipa = jo.id_echipa2)
                    HAVING avg(j.varsta) = (SELECT MIN(AVG(j.varsta))
                                                                 FROM antrenor a, echipa e, jucator j
                                                                WHERE e.id_echipa = a.id_echipa AND j.id_echipa = e.id_echipa AND (e.id_echipa = jo.id_echipa1 OR e.id_echipa = jo.id_echipa2)
                                                                GROUP BY e.id_echipa)
                    GROUP BY a.nume, a.prenume)
            FROM meci m, joaca jo
            WHERE m.data = meci_data AND m.id_meci = jo.id_meci;
            
        TYPE antrenori IS REF CURSOR;
        v_antrenori antrenori;
        v_data meci.data%TYPE;
        v_id_meci meci.id_meci%TYPE;
        v_nume_antrenor antrenor.nume%TYPE;
        v_prenume_antrenor antrenor.prenume%TYPE;
    
    BEGIN
        OPEN meciuri(data_introdusa);
        LOOP
            FETCH meciuri into v_id_meci, v_data, v_antrenori;
            EXIT WHEN meciuri%NOTFOUND;
            
            LOOP
                FETCH v_antrenori into v_nume_antrenor, v_prenume_antrenor;
                EXIT WHEN v_antrenori%NOTFOUND;
                DBMS_OUTPUT.PUT_LINE('Antrenor:' || ' ' || v_nume_antrenor || ' ' || v_prenume_antrenor);
            END LOOP;
            DBMS_OUTPUT.PUT_LINE('---------------------------');
            
        END LOOP;
        CLOSE meciuri;
            
    END p7_AntrenoriVarsta;
    
 -- 8. ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
    FUNCTION p8_AfisareStadion(nume_sponsor sponsor.nume%TYPE)
        RETURN VARCHAR2 IS
        v_rezultat VARCHAR2(20);
        v_sponsor sponsor.nume%TYPE := nume_sponsor;
        v_sponsor_tabel NUMBER := 0;
        
    BEGIN
        SELECT count(*) INTO v_sponsor_tabel
        FROM sponsor
        WHERE lower(nume) = lower(nume_sponsor);
        
        IF v_sponsor_tabel = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Nu exista sponsorul dat ca parametru!');
        END IF;
        
        SELECT s.nume INTO v_rezultat
        FROM stadion s, sponsor sp, echipa e
        WHERE e.id_stadion = s.id_stadion AND e.id_echipa = sp.id_echipa and lower(sp.nume) = lower(nume_sponsor);
        
        RETURN v_rezultat;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Sponsorul dat ca parametru nu sponsorizeaza nicio echipa!');
        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(-20003, 'Prea multe date');
        
    END p8_AfisareStadion;
    
-- 9. ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
 
     PROCEDURE p9_AfisareNationala(param_id_meci meci.id_meci%TYPE, param_post jucator.post%TYPE) IS
        v_nationala_nume nationala.nume%TYPE;
        v_jucator_nume jucator.nume%TYPE;
        v_jucator_prenume jucator.prenume%TYPE;
        v_jucator_numar jucator.numar%TYPE;
        v_jucator_varsta jucator.varsta%TYPE;
        v_meci_tabel NUMBER(2) := 0;
        v_post_tabel NUMBER(2) := 0;
        v_post_echipe NUMBER(2) := 0;
    
    BEGIN
        SELECT COUNT(*) INTO v_meci_tabel
        FROM meci
        WHERE id_meci = param_id_meci;
        
        IF v_meci_tabel = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Nu exista niciun meci cu id-ul dat ca parametru!');    
        END IF;
        
        SELECT COUNT(*) INTO v_post_tabel
        FROM jucator
        WHERE post = param_post;
        
        IF v_post_tabel = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Nu exista niciun post cu denumirea postului dat ca parametru!');
        END IF;
            
        SELECT COUNT(*) into v_post_echipe
        FROM echipa e, meci m, joaca j, jucator ju
        WHERE m.id_meci = j.id_meci
        AND (e.id_echipa = j.id_echipa1 OR e.id_echipa = j.id_echipa2)
        AND ju.id_echipa = e.id_echipa 
        AND m.id_meci = param_id_meci  
        AND ju.post = param_post;
        
        IF v_post_echipe = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Nu exista niciun jucator care sa joace pe postul dat ca parametru in una din cele 2 echipa care joaca in meciul dat ca parametru!');
        END IF;
        
        SELECT n.nume, ju.nume, ju.prenume, ju.numar, ju.varsta INTO v_nationala_nume, v_jucator_nume, v_jucator_prenume, v_jucator_numar, v_jucator_varsta
        FROM nationala n, joaca j, echipa e, jucator ju, meci m
        WHERE ju.id_nationala = n.id_nationala 
        AND ju.id_echipa = e.id_echipa 
        AND (e.id_echipa = j.id_echipa1 OR e.id_echipa = j.id_echipa2) 
        AND j.id_meci = m.id_meci 
        AND m.id_meci = param_id_meci 
        AND ju.post = param_post
        AND id_nationale IS NOT NULL
        AND ju.varsta = (SELECT MAX(ju.varsta)
                                     FROM nationala n, joaca j, echipa e, jucator ju, meci m
                                     WHERE ju.id_nationala = n.id_nationala 
                                     AND ju.id_echipa = e.id_echipa 
                                     AND (e.id_echipa = j.id_echipa1 OR e.id_echipa = j.id_echipa2) 
                                     AND j.id_meci = m.id_meci 
                                     AND m.id_meci = param_id_meci 
                                     AND ju.post = param_post
                                     AND id_nationale IS NOT NULL);
                                     
        DBMS_OUTPUT.PUT_LINE('Nationala: ' ||  v_nationala_nume);
        DBMS_OUTPUT.PUT_LINE('Nume: '  || v_jucator_nume);
        DBMS_OUTPUT.PUT_LINE('Prenume: ' || v_jucator_prenume);
        DBMS_OUTPUT.PUT_LINE('Numar: ' || v_jucator_numar);
        DBMS_OUTPUT.PUT_LINE( 'Varsta: ' || v_jucator_varsta);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Jucatorul nu apartine de o nationala calificata la campionatul euroean!');
        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(-20005, 'Exista mai mult de 1 jucator cu varsta maxima intr-o nationala calificata la campionatul european.');
            
    END p9_AfisareNationala;
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 END ex13_PachetProiect;
 /
 -- Test functii / proceduri pachet
 
 -- 6.
 exec ex13_PachetProiect.p6_SelectareAntrenori;

 
 -- 7.
 exec ex13_PachetProiect.p7_AntrenoriVarsta('18-APR-22');
 
 -- 8.
BEGIN
    DBMS_OUTPUT.PUT_LINE('Rezultatul este: ' || ex13_PachetProiect.p8_AfisareStadion('City Insurance'));
END;
/

-- 9.
exec  ex13_PachetProiect.p9_AfisareNationala(215, 'atacant');


-- 14.

-- Vreau ca fiecare jucator sa fie exclus de la echipa nationala la care joaca daca varsta lui este mai mare de 30 de ani. Vreau sa se afiseze jucatorii antrenati de un antrenor si echipa la care joaca, iar in dreptul lor sa scrie 
-- daca sunt convocati, nationala la care joaca, iar daca nu sa scrie 'neconvocat'.

CREATE OR REPLACE PACKAGE ex14_PachetProiect_jucatori AS
    PROCEDURE populeaza_date;
    PROCEDURE exclude_jucatori;
    FUNCTION cauta_echipa_antrenor(antrenor_id antrenor.id_antrenor%TYPE) RETURN VARCHAR2;
    FUNCTION cauta_nationala_jucator(jucator_id jucator.id_nationala%TYPE) RETURN VARCHAR2;
    PROCEDURE afisare_date;
    

END ex14_PachetProiect_jucatori;
/

CREATE OR REPLACE PACKAGE BODY ex14_PachetProiect_jucatori AS

    TYPE jucatori IS TABLE OF
        jucator%ROWTYPE
        INDEX BY PLS_INTEGER;
        v_jucatori jucatori;
        
    TYPE vector_antrenori IS VARRAY(50) OF
        antrenor%ROWTYPE;
        v_antr vector_antrenori;
        
    PROCEDURE populeaza_date IS
        BEGIN
            SELECT jucator.* BULK COLLECT INTO v_jucatori
            FROM jucator;
            
            SELECT antrenor.* BULK COLLECT INTO v_antr
            FROM antrenor;
        END populeaza_date;
        
    PROCEDURE exclude_jucatori IS
        BEGIN
                UPDATE jucator SET id_nationala = null
                WHERE varsta >  30;
        END exclude_jucatori;
        
        FUNCTION  cauta_echipa_antrenor(antrenor_id antrenor.id_antrenor%TYPE) RETURN VARCHAR2 IS
            v_id_echipa echipa.id_echipa%TYPE;
            v_nume_echipa echipa.nume%TYPE;
        BEGIN
            SELECT id_echipa INTO v_id_echipa
            FROM antrenor
            WHERE id_antrenor = antrenor_id;
            
            SELECT nume INTO v_nume_echipa
            FROM echipa
            WHERE v_id_echipa = id_echipa;
            
            RETURN v_nume_echipa;
        END cauta_echipa_antrenor;
        
        FUNCTION cauta_nationala_jucator(jucator_id jucator.id_nationala%TYPE) RETURN VARCHAR2 IS
            v_nume_nationala nationala.nume%TYPE;
        BEGIN
            IF jucator_id IS NULL THEN
                RETURN 'Neconvocat';
            END IF;
            
            SELECT nume INTO v_nume_nationala
            FROM nationala
            WHERE jucator_id = id_nationala;
            
            RETURN v_nume_nationala;
        END cauta_nationala_jucator;
        
        PROCEDURE afisare_date IS
        BEGIN
            exclude_jucatori;
            populeaza_date;
            FOR ind IN v_antr.FIRST..v_antr.LAST LOOP
                DBMS_OUTPUT.PUT_LINE('Antrenor: ' || ' ' || v_antr(ind).nume || ' ' || v_antr(ind).prenume || '  ' || LPAD('Echipa antrenata: ' || ' ' || cauta_echipa_antrenor(v_antr(ind).id_antrenor),48));
                DBMS_OUTPUT.PUT_LINE('Lista jucatori: ' || '                     ' || LPAD('Convocat/Neconvocat nationala:',48));
                FOR jnd IN v_jucatori.FIRST..v_jucatori.LAST LOOP
                    IF v_antr(ind).id_echipa = v_jucatori(jnd).id_echipa THEN
                        DBMS_OUTPUT.PUT_LINE(RPAD(v_jucatori(jnd).nume || ' ' || v_jucatori(jnd).prenume, 50) || ' ' || LPAD(cauta_nationala_jucator(v_jucatori(jnd).id_nationala), 30));
                    END IF;
                END LOOP;
                DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------------------------------------');
            END LOOP;
        END afisare_date;
        
END ex14_PachetProiect_jucatori;
/

BEGIN
    ex14_pachetproiect_jucatori.afisare_date;
END;
/

