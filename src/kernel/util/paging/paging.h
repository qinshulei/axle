#ifndef PAGING_H
#define PAGING_H

#include <std/common.h>
#include <kernel/util/interrupts/isr.h>

typedef struct page {
	uint32_t present	:  1; //page present in memory
	uint32_t rw	:  1; //read-only if clear, readwrite if set
	uint32_t user 	:  1; //kernel level only if clear
	uint32_t accessed	:  1; //has page been accessed since last refresh?
	uint32_t dirty	:  1; //has page been written to since last refresh?
	uint32_t unused	:  7; //unused/reserved bits
	uint32_t frame	: 20; //frame address, shifted right 12 bits
} page_t;

typedef struct page_table {
	page_t pages[1024];
} page_table_t;

typedef struct page_directory {
	//array of pointers to pagetables
	page_table_t* tables[1024];

	//array of pointers to pagetables above, but give their *physical*
	//location, for loading into CR3 reg
	uint32_t tablesPhysical[1024];

	//physical addr of tablesPhysical. 
	//needed once kernel heap is allocated and
	//directory may be in a different location in virtual memory
	uint32_t physicalAddr;
} page_directory_t;

//sets up environment, page directories, etc
//and, enables paging
void paging_install();

//causes passed page directory to be loaded into 
//CR3 register
void switch_page_directory(page_directory_t* new);

//retrieves pointer to page required
//if make == 1, if the page-table in which this page should
//reside isn't created, create it
page_t* get_page(uint32_t address, int make, page_directory_t* dir);

void alloc_frame(page_t* page, int is_kernel, int is_writeable);

//handler for page faults
void page_fault(registers_t* regs);

page_directory_t* clone_directory(page_directory_t* src);

#endif
