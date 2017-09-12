with
  Pn.Classes,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Domains,
  Pn.Compiler.Event,
  Pn.Compiler.Mappings,
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Compiler.Names,
  Pn.Guards,
  Pn.Nodes,
  Pn.Vars;

use
  Pn.Classes,
  Pn.Compiler.Bit_Stream,
  Pn.Compiler.Domains,
  Pn.Compiler.Event,
  Pn.Compiler.Mappings,
  Pn.Compiler.State,
  Pn.Compiler.Util,
  Pn.Compiler.Names,
  Pn.Guards,
  Pn.Nodes,
  Pn.Vars;

package body Pn.Compiler.Event_Set is

   --==========================================================================
   --  a set of enabled transitions
   --==========================================================================

   procedure Gen_Event_Set
     (N: in Net;
      L: in Library) is
      Prototype: Ustring;
      T        : Trans;
      Ts       : constant Trans_Vector := Get_Trans(N);
   begin
      Plh(L, "typedef uint8_t mevent_id_t;");
      Plh(L, "typedef struct struct_mevent_list_t {");
      Plh(L, 1, "mevent_t e;");
      Plh(L, 1, "mevent_id_t id;");
      Plh(L, 1, "struct struct_mevent_list_t * next;");
      Plh(L, "} struct_mevent_list_t;");
      Plh(L, "typedef struct_mevent_list_t * mevent_list_t;");
      Plh(L, "typedef struct {");
      Plh(L, 1, "mevent_list_t first;");
      Plh(L, 1, "unsigned char size;");
      Plh(L, 1, "heap_t heap;");
      Plh(L, "} struct_mevent_set_t;");
      Plh(L, "typedef struct_mevent_set_t * mevent_set_t;");
      Plh(L, "typedef bool_t (* pred_event_t) (mevent_t);");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_list_free (" & Nl &
	   "   mevent_list_t l," & Nl &
	   "   heap_t heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_list_t tmp = l, tmp_next;");
      Plc(L, 1, "for(; tmp; tmp=tmp_next) {");
      Plc(L, 2, "tmp_next = tmp->next;");
      Plc(L, 2, "mevent_free_mem (tmp->e, heap);");
      Plc(L, 2, "mem_free (heap, tmp);");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_list_t mevent_list_copy (" & Nl &
	   "   mevent_list_t l," & Nl &
	   "   heap_t heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_list_t result = NULL, tmp = l, new_node, current;");
      Plc(L, 1, "for(; tmp; tmp = tmp->next) {");
      Plc(L, 2, "new_node = mem_alloc (heap, sizeof (struct_mevent_list_t));");
      Plc(L, 2, "new_node->e = mevent_copy_mem (tmp->e, heap);");
      Plc(L, 2, "new_node->id = tmp->id;");
      Plc(L, 2, "new_node->next = NULL;");
      Plc(L, 2, "if (NULL == result) {");
      Plc(L, 3, "result = new_node;");
      Plc(L, 3, "current = new_node;");
      Plc(L, 2, "} else {");
      Plc(L, 3, "current->next = new_node;");
      Plc(L, 3, "current = current->next;");
      Plc(L, 2, "}");
      Plc(L, 1, "}");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_list_t mevent_list_filter (" & Nl &
	   "   mevent_list_t l," & Nl &
	   "   pred_event_t keep," & Nl &
	   "   unsigned char * size," & Nl &
	   "   heap_t heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_list_t result = NULL, tmp = l, tmp_next, " &
	    "tmp_last = NULL;");
      Plc(L, 1, "*size = 0;");
      Plc(L, 1, "for(; tmp; tmp = tmp_next) {");
      Plc(L, 2, "tmp_next = tmp->next;");
      Plc(L, 2, "if (keep (tmp->e)) {");
      Plc(L, 3, "(*size) ++;");
      Plc(L, 3, "if (NULL == result) {");
      Plc(L, 4, "result = tmp;");
      Plc(L, 3, "}");
      Plc(L, 3, "tmp_last = tmp;");
      Plc(L, 2, "} else {");
      Plc(L, 3, "mevent_free_mem (tmp->e, heap);");
      Plc(L, 3, "mem_free (heap, tmp);");
      Plc(L, 3, "if (tmp_last != NULL) {");
      Plc(L, 4, "tmp_last->next = tmp_next;");
      Plc(L, 3, "}");
      Plc(L, 2, "}");
      Plc(L, 1, "}");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Plh(L, "#define mevent_set_size(evts) (evts->size)");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_set_print (" & Nl &
	   "   mevent_set_t evts)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_list_t tmp = evts->first;");
      Plc(L, 1, "for(; tmp; tmp=tmp->next) {");
      Plc(L, 2, "switch(tmp->e.tid) {");
      for I in 1..T_Size(N) loop
         T := Ith_Trans(N, I);
         Plc(L, 3, "case " & Tid(T) & ":");
         Plc(L, 4, "printf(""" &
	       Get_Printable_String(Get_Name(T)) & ", "");");
         Plc(L, 4, Trans_Dom_Print_Func(T) &
	       "((* ((" & Trans_Dom_Type(T) & "*) tmp->e.c)));");
	 Plc(L, 4, "printf(""\n"");");
         Plc(L, 4, "break;");
      end loop;
      Plc(L, 2, "}");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("void mevent_set_free (" & Nl &
	   "   mevent_set_t evts)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "if (!heap_has_mem_free (evts->heap)) { return; }");
      Plc(L, 1, "mevent_list_free (evts->first, evts->heap);");
      Plc(L, 1, "mem_free (evts->heap, evts);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("mevent_set_t mevent_set_copy_mem (" & Nl &
	   "   mevent_set_t evts," & Nl &
	   "   heap_t      heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_set_t result;");
      Plc(L, 1, "result = (mevent_set_t) " &
	    "mem_alloc (heap, sizeof(struct_mevent_set_t));");
      Plc(L, 1, "result->heap = heap;");
      Plc(L, 1, "result->size = evts->size;");
      Plc(L, 1, "result->first = mevent_list_copy (evts->first, heap);");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
        ("mevent_set_t mevent_set_copy (" & Nl &
	   "   mevent_set_t evts)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "return mevent_set_copy_mem (evts, SYSTEM_HEAP);");
      Plc(L, "}");
      --=======================================================================
      Plh(L, "#define mevent_set_init(evts, evts_heap) { \");
      Plh(L, 1, "evts = (mevent_set_t) " &
	    "mem_alloc (evts_heap, sizeof(struct_mevent_set_t)); \");
      Plh(L, 1, "evts->size = 0; \");
      Plh(L, 1, "evts->first = NULL; \");
      Plh(L, 1, "evts->heap = evts_heap; \");
      Plh(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_t mevent_set_nth (" & Nl &
	   "   mevent_set_t evts," & Nl &
	   "   unsigned int n)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "unsigned int i = 0;");
      Plc(L, 1, "mevent_list_t tmp = evts->first;");
      Plc(L, 1, "for (; i < n; i ++, tmp = tmp->next);");
      Plc(L, 1, "return tmp->e;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_id_t mevent_set_nth_id (" & Nl &
	   "   mevent_set_t evts," & Nl &
	   "   unsigned int n)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "unsigned int i = 0;");
      Plc(L, 1, "mevent_list_t tmp = evts->first;");
      Plc(L, 1, "for (; i < n; i ++, tmp = tmp->next);");
      Plc(L, 1, "return tmp->id;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("unsigned int mevent_set_char_width (" & Nl &
	   "   mevent_set_t evts)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "unsigned int result = sizeof (unsigned char);");
      Plc(L, 1, "mevent_list_t tmp = evts->first;");
      Plc(L, 1, "for(; tmp; tmp=tmp->next) {");
      Plc(L, 2, "result += sizeof (mevent_id_t)" &
	    " + mevent_char_width (tmp->e);");
      Plc(L, 1, "}");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_set_serialise (" & Nl &
	   "   mevent_set_t  evts," & Nl &
	   "   bit_vector_t v)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "mevent_list_t tmp = evts->first;");
      Plc(L, 1, "unsigned int pos = 1;");
      Plc(L, 1, "v[0] = evts->size;");
      Plc(L, 1, "for(; tmp; tmp=tmp->next) {");
      Plc(L, 2, "memcpy (&v[pos], &tmp->id, sizeof (mevent_id_t));");
      Plc(L, 2, "mevent_serialise "
	    & "(tmp->e, &(v[pos + sizeof (mevent_id_t)]));");
      Plc(L, 2, "pos += sizeof (mevent_id_t) + mevent_char_width (tmp->e);");
      Plc(L, 1, "}");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_set_t mevent_set_unserialise_mem (" & Nl &
	   "   bit_vector_t v," & Nl &
	   "   heap_t       heap)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "int i, pos = 1;");
      Plc(L, 1, "mevent_list_t last = NULL, new_node;");
      Plc(L, 1, "mevent_set_t result;");
      Plc(L, 1, "mevent_set_init (result, heap);");
      Plc(L, 1, "result->size = v[0];");
      Plc(L, 1, "for (i = 0; i < result->size; i ++) {");
      Plc(L, 2, "new_node = mem_alloc (heap, sizeof (struct_mevent_list_t));");
      Plc(L, 2, "memcpy (&new_node->id, &v[pos], sizeof (mevent_id_t));");
      Plc(L, 2, "new_node->e = mevent_unserialise_mem " &
	    "(&(v[pos + sizeof (mevent_id_t)]), heap);");
      Plc(L, 2, "new_node->next = NULL;");
      Plc(L, 2, "if (0 == i) {");
      Plc(L, 3, "result->first = new_node;");
      Plc(L, 2, "} else {");
      Plc(L, 3, "last->next = new_node;");
      Plc(L, 2, "}");
      Plc(L, 2, "last = new_node;");
      Plc(L, 2, "pos += sizeof (mevent_id_t) + " &
	    "mevent_char_width (new_node->e);");
      Plc(L, 1, "}");
      Plc(L, 1, "return result;");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("mevent_set_t mevent_set_unserialise (" & Nl &
	   "   bit_vector_t v)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "return mevent_set_unserialise_mem (v, SYSTEM_HEAP);");
      Plc(L, "}");
      --=======================================================================
      Prototype := To_Ustring
	("void mevent_set_filter (" & Nl &
	   "   mevent_set_t evts," & Nl &
	   "   pred_event_t keep)");
      Plh(L, Prototype & ";");
      Plc(L, Prototype & " {");
      Plc(L, 1, "evts->first = " &
	    "mevent_list_filter (evts->first, keep, &evts->size, evts->heap);");
      Plc(L, "}");
   end;



   procedure Gen
     (N   : in Net;
      Path: in Ustring) is
      Comment  : constant String := "This library implements event set.";
      Lib      : Library;
      Prototype: Ustring;
   begin
      Init_Library(Event_Set_Lib, To_Ustring(Comment), Path, Lib);
      Plh(Lib, "#include ""mevent.h""");
      Plh(Lib, "#include ""mstate.h""");
      Gen_Event_Set(N, Lib);
      Prototype := "void " & Lib_Init_Func(Event_Set_Lib) & Nl & "()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {}");
      Prototype := "void " & Lib_Free_Func(Event_Set_Lib) & Nl & "()";
      Plh(Lib, Prototype & ";");
      Plc(Lib, Prototype & " {}");
      End_Library(Lib);
   end;

end Pn.Compiler.Event_Set ;
