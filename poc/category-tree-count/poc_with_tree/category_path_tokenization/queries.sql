EXPLAIN SELECT DISTINCT code
FROM pimee_security_product_category_access ca
JOIN pim_catalog_category c ON ca.category_id = c.id 
WHERE ca.user_group_id IN (1,4) 
AND ca.view_items = 1 
AND ((c.rgt < 3332 AND c.lft > 1 AND c.root = 1) OR c.id = 1);



    SELECT parent.code as parent_code, GROUP_CONCAT(node.code) as node_code 
    FROM pim_catalog_category AS node 
    JOIN pim_catalog_category AS parent ON node.root = parent.root
    JOIN pim_catalog_category as parent_node ON parent_node.id = parent.parent_id
    JOIN pimee_security_product_category_access ca on ca.category_id = node.id 
    WHERE parent_node.code = 'master' 
    AND ca.user_group_id IN (1, 4) 
    AND ca.view_items = 1
    AND node.lft BETWEEN parent.lft AND parent.rgt
    GROUP BY parent.code
    ORDER BY parent.lft;
    
    
    
    
    SELECT parent.code as parent_code, node.code as node_code 
    FROM pim_catalog_category AS node 
    JOIN pim_catalog_category AS parent ON node.root = parent.root
    JOIN pim_catalog_category as parent_node ON parent_node.id = parent.parent_id
    JOIN pimee_security_product_category_access ca on ca.category_id = node.id 
    WHERE parent_node.code = 'master' 
    AND ca.user_group_id IN (1, 4) 
    AND ca.view_items = 1
    AND node.lft BETWEEN parent.lft AND parent.rgt
    ORDER BY parent.lft;
    
    SELECT parent.code as parent_code, GROUP_CONCAT(node.code) as node_code 
    FROM pim_catalog_category AS node 
    JOIN pim_catalog_category AS parent ON node.root = parent.root
    JOIN pim_catalog_category as parent_node ON parent_node.id = parent.parent_id
    WHERE parent_node.code = 'master'
    AND node.lft BETWEEN parent.lft AND parent.rgt
    GROUP BY parent.code
    ORDER BY parent.lft;
    
    SELECT parent.code as parent_code, node.code as node_code 
    FROM pim_catalog_category AS node 
    JOIN pim_catalog_category AS parent ON node.root = parent.root
    JOIN pim_catalog_category as parent_node ON parent_node.id = parent.parent_id
    WHERE parent_node.code = 'master'
    AND node.lft BETWEEN parent.lft AND parent.rgt
    -- GROUP BY parent.code
    ORDER BY parent.lft;
    
    
    SELECT parent.code as parent_code, node.code as node_code 
    FROM pim_catalog_category AS node 
    JOIN pim_catalog_category AS parent ON node.root = parent.root
    JOIN pim_catalog_category as parent_node ON parent_node.id = parent.parent_id
    WHERE parent_node.code = 'master'
    AND node.lft BETWEEN parent.lft AND parent.rgt
    -- GROUP BY parent.code
    ORDER BY parent.lft;
    
	SELECT child.code as child_code, subchild.code as subchild_code
	FROM pim_catalog_category parent
	JOIN pim_catalog_category child on child.parent_id = parent.id
	JOIN pim_catalog_category subchild on subchild.lft BETWEEN child.lft AND child.rgt AND subchild.root = child.root
	WHERE parent.parent_id IS NULL;
	
	SELECT child.code as child_code, subchild.code as subchild_code
	FROM pim_catalog_category parent
	JOIN pim_catalog_category child on child.parent_id = parent.id
	JOIN pim_catalog_category subchild on subchild.lft BETWEEN child.lft AND child.rgt AND subchild.root = child.root
	JOIN pimee_security_product_category_access ca on ca.category_id = subchild.id 
	WHERE parent.code = 'master'
	AND ca.user_group_id IN (1, 4) 
    AND ca.view_items = 1
	;
	
	
	SELECT 
		child.code as child_code, 
		subchild.code
	FROM pim_catalog_category child
	JOIN pim_catalog_category subchild on subchild.lft BETWEEN child.lft AND child.rgt AND subchild.root = child.root
	JOIN pimee_security_product_category_access ca on ca.category_id = subchild.id 
	WHERE child.parent_id IS NULL
	AND ca.user_group_id IN (1, 4)
    AND ca.view_items = 1
    -- GROUP BY child.code
	;
	
	SELECT c.child_code, GROUP_CONCAT(c.subchild_code) FROM (
	SELECT child.code as child_code,  subchild.code as subchild_code
	FROM pim_catalog_category parent
	JOIN pim_catalog_category child on child.parent_id = parent.id
	JOIN pim_catalog_category subchild on subchild.lft BETWEEN child.lft AND child.rgt AND subchild.root = child.root
	JOIN pimee_security_product_category_access ca on ca.category_id = subchild.id 
	WHERE parent.code = 'master'
	AND ca.user_group_id IN (1, 4)
    AND ca.view_items = 1 ) as c
   	GROUP BY c.child_code
	;
	
	
    CREATE INDEX test_category_access ON pimee_security_product_category_access (view_items, user_group_id);
    CREATE INDEX test_category ON pim_catalog_category (lft, rgt);

    DROP INDEX test_category_access on pimee_security_product_category_access;
    DROP INDEX test_category on pim_catalog_category;
    
	select parent_code, GROUP_CONCAT(child_code) from test GROUP BY parent_code;
	
	TRUNCATE TABLE test;
	CREATE TABLE test (
		id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
		parent_code VARCHAR(30) NOT NULL,
		child_code VARCHAR(30) NOT NULL,
		PRIMARY KEY (id)
	) ENGINE=InnoDB;


    
    select @@sql_mode;
    set global sql_mode='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
    
    select * from pim_catalog_category;


SELECT path.node_code, JSON_ARRAYAGG(path.parent_code)
FROM (
    SELECT node.code as node_code, parent.code as parent_code
    FROM pim_catalog_category AS node,
    pim_catalog_category AS parent
    WHERE node.lft BETWEEN parent.lft AND parent.rgt
    ORDER BY parent.lft
) as path
GROUP BY path.node_code;
