/* Add one observed graphics-domain self:process execmem permission offline.
 * The input file is read-only. Semantic scope is verified by restoring the
 * bit in the output policy and comparing canonical serializations. */
#include <sepol/policydb.h>
#include <sepol/policydb/policydb.h>
#include <sepol/policydb/avtab.h>
#include <sepol/policydb/hashtab.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void fail(const char *message) { fprintf(stderr,"ERROR: %s\n",message);exit(1); }
static void *read_file(const char *path,size_t *size) {
 FILE *f=fopen(path,"rb"); if(!f)fail("cannot read input policy");
 if(fseek(f,0,SEEK_END)||ftell(f)<=0)fail("invalid input size");
 *size=ftell(f);if(*size>32*1024*1024)fail("policy exceeds size cap");
 rewind(f);void *p=malloc(*size);if(!p||fread(p,1,*size,f)!=*size)fail("short input read");
 fclose(f);return p;
}
static void serialize(sepol_policydb_t *p,void **out,size_t *size) {
 if(sepol_policydb_to_image(NULL,p,out,size))fail("policy serialization failed");
}
static void remove_rule(avtab_t *table,const avtab_key_t *key) {
 for(uint32_t i=0;i<table->nslot;i++) {
  avtab_ptr_t *link=&table->htable[i];
  while(*link) {
   avtab_ptr_t node=*link;
   if(!memcmp(&node->key,key,sizeof(*key))) {
    if(node->datum.xperms)fail("unexpected extended permission");
    *link=node->next;free(node);table->nel--;return;
   }
   link=&node->next;
  }
 }
 fail("cannot revert inserted rule");
}
int main(int argc,char **argv) {
 if(argc!=7)fail("usage: allow_graphics_execmem INPUT OUTPUT SOURCE TARGET CLASS PERMISSION (OUTPUT must not exist)");
 const char *domain=argv[3];

 size_t input_size;void *input=read_file(argv[1],&input_size);
 sepol_policydb_t *db=NULL,*check=NULL;
 if(sepol_policydb_create(&db)||sepol_policydb_from_image(NULL,input,input_size,db))fail("invalid input policy");
 policydb_t *p=&db->p;
 if(p->policy_type!=POLICY_KERN)fail("expected kernel policy");
 type_datum_t *type=hashtab_search(p->p_types.table,domain);
 type_datum_t *target=hashtab_search(p->p_types.table,argv[4]);
 class_datum_t *class=hashtab_search(p->p_classes.table,argv[5]);
 if(!type||type->flavor!=TYPE_TYPE||!target||target->flavor!=TYPE_TYPE||!class)fail("required concrete type/class missing");
 perm_datum_t *perm=hashtab_search(class->permissions.table,argv[6]);
 if(!perm&&class->comdatum)perm=hashtab_search(class->comdatum->permissions.table,argv[6]);
 if(!perm||!perm->s.value||perm->s.value>32)fail("execmem permission missing or invalid");
 if(type->s.value>UINT16_MAX||class->s.value>UINT16_MAX)fail("symbol index overflow");
 avtab_key_t key={.source_type=type->s.value,.target_type=target->s.value,
  .target_class=class->s.value,.specified=AVTAB_ALLOWED};
 uint32_t bit=1U<<(perm->s.value-1),count=p->te_avtab.nel;
 avtab_datum_t *rule=avtab_search(&p->te_avtab,&key);
 int existed=rule!=NULL;uint32_t before=existed?rule->data:0;

 void *baseline=NULL;size_t baseline_size;serialize(db,&baseline,&baseline_size);
 if(rule)rule->data|=bit;
 else {avtab_datum_t added={.data=bit};if(avtab_insert(&p->te_avtab,&key,&added))fail("cannot add rule");}
 void *output=NULL;size_t output_size;serialize(db,&output,&output_size);
 if(sepol_policydb_create(&check)||sepol_policydb_from_image(NULL,output,output_size,check))fail("output failed policy parser validation");
 rule=avtab_search(&check->p.te_avtab,&key);
 if(!rule||rule->data!=(before|bit)||check->p.te_avtab.nel!=count+!existed)fail("output rule verification failed");
 if(existed)rule->data=before;else remove_rule(&check->p.te_avtab,&key);
 /* Keep the same parse/write count on both branches: avtab permits
  * multiple extended-permission entries with the same key, whose traversal
  * order reverses during a parse. This is ordering, not a semantic change. */
 sepol_policydb_t *baseline_roundtrip=NULL;
 if(sepol_policydb_create(&baseline_roundtrip)||sepol_policydb_from_image(NULL,baseline,baseline_size,baseline_roundtrip))fail("baseline roundtrip failed");
 void *baseline_twice=NULL;size_t baseline_twice_size;
 serialize(baseline_roundtrip,&baseline_twice,&baseline_twice_size);
 free(baseline);baseline=baseline_twice;baseline_size=baseline_twice_size;
 sepol_policydb_free(baseline_roundtrip);
 void *reverted=NULL;size_t reverted_size;serialize(check,&reverted,&reverted_size);
 if(reverted_size!=baseline_size||memcmp(reverted,baseline,baseline_size))fail("output has changes beyond the single permission");
 FILE *f=fopen(argv[2],"wbx");if(!f)fail("cannot create output (must not already exist)");
 if(fwrite(output,1,output_size,f)!=output_size||fclose(f))fail("output write failed");
 printf("PASS policy_version=%u type=%s(%u) class_id=%u permission_id=%u\n",
  p->policyvers,domain,type->s.value,class->s.value,perm->s.value);
 printf("allow %s %s:%s %s;\n",domain,argv[4],argv[5],argv[6]);
 printf("avtab_rules_before=%u after=%u old_mask=%08x new_mask=%08x\n",count,count+!existed,before,before|bit);
 printf("PASS output reparses; reverting only this permission reproduces the original canonical policy byte-for-byte\n");
 printf("input_bytes=%zu output_bytes=%zu\n",input_size,output_size);
 free(input);free(output);free(baseline);free(reverted);sepol_policydb_free(db);sepol_policydb_free(check);return 0;
}
