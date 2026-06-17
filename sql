-- ============================================================
-- MEDICAL RESEARCH PUBLICATION & CONFERENCE MANAGEMENT SYSTEM
-- DATABASE MANAGEMENT SYSTEM (UCS310)
-- Thapar Institute of Engineering and Technology
-- Group 2C22 | Avraj Singh Sekhon, Chhavi Garg, Rashika Rathore
-- Submitted to: Dr. Damini Arora
-- ============================================================

-- ============================================================
-- STEP 1: CREATE ALL TABLES
-- ============================================================

-- 1. Author Table
CREATE TABLE Author (
    author_id   INT PRIMARY KEY,
    name        VARCHAR(100),
    affiliation VARCHAR(150),
    email       VARCHAR(100) UNIQUE
);

-- 2. Research Domain Table
CREATE TABLE Research_Domain (
    domain_id   INT PRIMARY KEY,
    domain_name VARCHAR(100)
);

-- 3. Research Paper Table
CREATE TABLE Research_Paper (
    paper_id         INT PRIMARY KEY,
    title            VARCHAR(200),
    publication_year INT,
    domain_id        INT,
    FOREIGN KEY (domain_id) REFERENCES Research_Domain(domain_id)
);

-- 4. Author_Paper (Junction Table - M:N between Author and Research_Paper)
CREATE TABLE Author_Paper (
    author_id INT,
    paper_id  INT,
    PRIMARY KEY (author_id, paper_id),
    FOREIGN KEY (author_id) REFERENCES Author(author_id),
    FOREIGN KEY (paper_id)  REFERENCES Research_Paper(paper_id)
);

-- 5. Reviewer Table
CREATE TABLE Reviewer (
    reviewer_id    INT PRIMARY KEY,
    name           VARCHAR(100),
    specialization VARCHAR(100),
    email          VARCHAR(100) UNIQUE
);

-- 6. Review Table
CREATE TABLE Review (
    review_id   INT PRIMARY KEY,
    rating      INT,
    comments    VARCHAR(300),
    paper_id    INT,
    reviewer_id INT,
    FOREIGN KEY (paper_id)    REFERENCES Research_Paper(paper_id),
    FOREIGN KEY (reviewer_id) REFERENCES Reviewer(reviewer_id)
);

-- 7. Conference Table
CREATE TABLE Conference (
    conf_id    INT PRIMARY KEY,
    conf_name  VARCHAR(150),
    location   VARCHAR(100),
    start_date DATE,
    end_date   DATE
);

-- 8. Submission Table
CREATE TABLE Submission (
    submission_id   INT PRIMARY KEY,
    submission_date DATE,
    status          VARCHAR(50),
    paper_id        INT,
    conf_id         INT,
    FOREIGN KEY (paper_id) REFERENCES Research_Paper(paper_id),
    FOREIGN KEY (conf_id)  REFERENCES Conference(conf_id)
);

-- 9. Paper_Presentation Table
CREATE TABLE Paper_Presentation (
    paper_id          INT,
    conf_id           INT,
    presentation_date DATE,
    PRIMARY KEY (paper_id, conf_id),
    FOREIGN KEY (paper_id) REFERENCES Research_Paper(paper_id),
    FOREIGN KEY (conf_id)  REFERENCES Conference(conf_id)
);

-- 10. Registration Table
CREATE TABLE Registration (
    reg_id    INT PRIMARY KEY,
    reg_date  DATE,
    author_id INT,
    conf_id   INT,
    FOREIGN KEY (author_id) REFERENCES Author(author_id),
    FOREIGN KEY (conf_id)   REFERENCES Conference(conf_id)
);

-- 11. Citation Table
CREATE TABLE Citation (
    citing_paper_id INT,
    cited_paper_id  INT,
    citation_year   INT,
    PRIMARY KEY (citing_paper_id, cited_paper_id),
    FOREIGN KEY (citing_paper_id) REFERENCES Research_Paper(paper_id),
    FOREIGN KEY (cited_paper_id)  REFERENCES Research_Paper(paper_id)
);

-- 12. Journal Table
CREATE TABLE Journal (
    journal_id    INT PRIMARY KEY,
    journal_name  VARCHAR(150),
    impact_factor DECIMAL(3,2)
);

-- ============================================================
-- END OF TABLE CREATION
-- ============================================================
