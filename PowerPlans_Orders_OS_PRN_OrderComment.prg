; Purpose:  Display Powerplans, Orders, Ordersentences, with PRN Reason (CS4005) of fever and Order Comment
; thanks to Aaron Britton in helping troublshoot CLOB errors with this query)
; By: lewis schmidt
; Date:  06/02/2015 


SELECT
            Powerplan = p.description
            , primary_mnemonic = oc.primary_mnemonic
;            , pco.order_sentence_id
         	, os.order_sentence_display_line
			, prn_reason = cv.display
            , L.long_text
;            , L.long_text_id
 
FROM
            pathway_catalog p
            , pathway_comp pc
            , order_catalog_synonym o
            , order_catalog oc
            , pw_comp_os_reltn pco
            , order_sentence os
            , long_text   l
            , code_value cv
    		, order_sentence_detail osd2
 
 
PLAN p ; Pathway_catalog
	WHERE p.pathway_catalog_id > 0
	;and P.description = "Abdominal Pain PEDS Surgery" ; to test for one specific powerplan
 
JOIN pc ; Pathway_comp
	WHERE pc.pathway_catalog_id = p.pathway_catalog_id
	and pc.parent_entity_id = (select distinct   ; nested query to get around CLOB error when using Distinct upfront
								o.synonym_id
								from
	 							order_catalog_synonym o
								where o.active_ind = 1
								and o.catalog_type_cd = 2516.00
								)
 
JOIN o ; Order_Catalog_Synonym
	WHERE o.synonym_id = outerjoin(pc.parent_entity_id)
 
JOIN oc ; Order_catalog
	WHERE oc.catalog_cd = outerjoin(o.catalog_cd)
 
JOIN pco ; PW_COMP_OS_RELTN
	WHERE pco.pathway_comp_id = outerjoin(pc.pathway_comp_id)
	and  pco.order_sentence_id = (select distinct   ; nested query to get around CLOB error when using Distinct upfront
								os.order_sentence_id
								from
	 							order_sentence os
								)
 
JOIN os ; ORDER_SENTENCE
	WHERE os.order_sentence_id = outerjoin(pco.order_sentence_id)
 	and os.usage_flag > 0
 
JOIN l ; LONG_TEXT
	WHERE l.long_text_id = os.ord_comment_long_text_id
	and l.active_ind = 1
 
Join cv ; code_value
	where cv.code_set = 4005
	and cv.display = "fever"
	or cv.display = "pain/fever"
	or cv.display = "fever/discomfort"
	or cv.display = "mild pain or fever"
 
join osd2; order_sentence_detail
        where osd2.order_sentence_id = os.order_sentence_id
        and osd2.default_parent_entity_name = "CODE_VALUE"
        and osd2.default_parent_entity_id = cv.code_value
 
 
ORDER BY
            p.description
            ,oc.primary_mnemonic
            , pco.order_sentence_id
 
WITH MAXREC = 2000, time = 300