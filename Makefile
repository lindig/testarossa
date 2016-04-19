# vim: set ts=8 sw=8 noet:
#
# Build tests in tests/ as stand-alone binaries
#

# -- global tags, local tags are in _tags
TAG += 		-tag annot
TAG += 		-tag bin_annot

SRC += 		-I tests
SRC += 		-I lib
SRC += 		-I scripts

# -- the binaries we are building
EXE += 		test_quicktest.native
EXE += 		get_vagrant_uuid.native
EXE += 		add_acls.native

OCB_FLAGS 	= -use-ocamlfind $(TAG) $(SRC)
OCB 		= ocamlbuild $(OCB_FLAGS)

all: 		kernels 
		$(OCB) $(EXE)

clean:
		$(OCB) -clean

# -- download kernels that we copy to hosts

kernels:
		cd xs/boot/guest && bash xen-test-vm.sh 0.0.5

# -- use this to quickly infer an MLI file: 
%.mli: 		%.ml
		$(OCB) $(*).inferred.mli

# -- generic pattern - just passed to OCB
%:		
		$(OCB) $*

.PHONY: all clean kernels

