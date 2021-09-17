!> Implements a dynamic stack ADT
!! @details a stack storing values @a data of an arbitrary type
module stack
  use num_types
  use tuple
  use nmsh
  use utils
  use structs
  use math, only : NEKO_M_LN2
  implicit none
  private

  integer, parameter :: NEKO_STACK_SIZE_T = 32

  !> Base type for a stack
  type, abstract, private :: stack_t
     class(*),  allocatable :: data(:)
     integer :: top_
     integer :: size_
   contains
     procedure, non_overridable, pass(this) :: init => stack_init
     procedure, non_overridable, pass(this) :: free => stack_free
     procedure, non_overridable, pass(this) :: clear => stack_clear
     procedure, non_overridable, pass(this) :: size => stack_size
     procedure, non_overridable, pass(this) :: push => stack_push
  end type stack_t

  !> Integer based stack
  type, public, extends(stack_t) :: stack_i4_t
   contains
     procedure, public, pass(this) :: pop => stack_i4_pop
     procedure, public, pass(this) :: array => stack_i4_data
  end type stack_i4_t

  !> Integer*8 based stack
  type, public, extends(stack_t) :: stack_i8_t
   contains
     procedure, public, pass(this) :: pop => stack_i8_pop
     procedure, public, pass(this) :: array => stack_i8_data
  end type stack_i8_t

  !> Double precision based stack
  type, public, extends(stack_t) :: stack_r8_t
   contains
     procedure, public, pass(this) :: pop => stack_r8_pop
     procedure, public, pass(this) :: array => stack_r8_data
  end type stack_r8_t

  !> Integer 2-tuple based stack
  type, public, extends(stack_t) :: stack_i4t2_t
   contains
     procedure, public, pass(this) :: pop => stack_i4t2_pop
     procedure, public, pass(this) :: array => stack_i4t2_data
  end type stack_i4t2_t

  !> Integer 4-tuple based stack
  type, public, extends(stack_t) :: stack_i4t4_t
   contains
     procedure, public, pass(this) :: pop => stack_i4t4_pop
     procedure, public, pass(this) :: array => stack_i4t4_data
  end type stack_i4t4_t
  
  !> Curved element stack
  type, public, extends(stack_t) :: stack_curve_t
   contains
     procedure, public, pass(this) :: pop => stack_curve_element_pop
     procedure, public, pass(this) :: array => stack_curve_element_data
  end type stack_curve_t

  !> Neko quad element based stack
  type, public, extends(stack_t) :: stack_nq_t
   contains
     procedure, public, pass(this) :: pop => stack_nq_pop
     procedure, public, pass(this) :: array => stack_nq_data
  end type stack_nq_t

  !> Neko hex element based stack
  type, public, extends(stack_t) :: stack_nh_t
   contains
     procedure, public, pass(this) :: pop => stack_nh_pop
     procedure, public, pass(this) :: array => stack_nh_data
  end type stack_nh_t

  !> Neko zone based stack
  type, public, extends(stack_t) :: stack_nz_t
   contains
     procedure, public, pass(this) :: pop => stack_nz_pop
     procedure, public, pass(this) :: array => stack_nz_data
  end type stack_nz_t

  !> Neko curve info based stack
  type, public, extends(stack_t) :: stack_nc_t
   contains
     procedure, public, pass(this) :: pop => stack_nc_pop
     procedure, public, pass(this) :: array => stack_nc_data
  end type stack_nc_t

contains

  !> Initialize a stack of arbitrary type 
  subroutine stack_init(this, size)
    class(stack_t), intent(inout) :: this 
    integer, optional :: size !< Initial size of the stack
    integer :: size_t

    if (present(size)) then
       if (size .gt. 0) then
          size_t = size
       else
          call neko_warning('Invalid stack size, using default')
          size_t = NEKO_STACK_SIZE_T
       end if
    else
       size_t = NEKO_STACK_SIZE_T
    end if

    this%size_ = ishft(1, ceiling(log(real(size_t, rp)) / NEKO_M_LN2))
    this%top_ = 0
    select type(this)
    type is(stack_i4_t)
       allocate(integer::this%data(this%size_))
    type is(stack_i8_t)
       allocate(integer(8)::this%data(this%size_))
    type is (stack_r8_t)
       allocate(double precision::this%data(this%size_))
    type is (stack_i4t2_t)
       allocate(tuple_i4_t::this%data(this%size_))
    type is (stack_i4t4_t)
       allocate(tuple4_i4_t::this%data(this%size_))
    type is (stack_curve_t)
       allocate(struct_curve_t::this%data(this%size_))
    type is (stack_nq_t)
       allocate(nmsh_quad_t::this%data(this%size_))
    type is (stack_nh_t)
       allocate(nmsh_hex_t::this%data(this%size_))
    type is (stack_nz_t)
       allocate(nmsh_zone_t::this%data(this%size_))
    type is (stack_nc_t)
       allocate(nmsh_curve_el_t::this%data(this%size_))
    end select

  end subroutine stack_init
  
  !> Destroy a stack
  subroutine stack_free(this)
    class(stack_t), intent(inout) :: this
    
    if (allocated(this%data)) then
       deallocate(this%data)
       this%size_ = 0 
       this%top_ = 0
    end if    

  end subroutine stack_free

  !> Clear all entries of a stack
  subroutine stack_clear(this)
    class(stack_t), intent(inout) :: this
    this%top_ = 0
  end subroutine stack_clear

  !> Return number of entries in the stack
  pure function stack_size(this) result(size)
    class(stack_t), intent(in) :: this
    integer :: size
    size = this%top_
  end function stack_size

  !> Push data onto the stack
  subroutine stack_push(this, data)
    class(stack_t), target, intent(inout) :: this
    class(*), intent(inout) :: data !< Arbitrary typed data (same type as stack)
    class(*), allocatable :: tmp(:)

    if (this%top_ .eq. this%size_) then
       this%size_ = ishft(this%size_, 1)
       select type(data)
       type is(integer)
          allocate(integer::tmp(this%size_))
       type is(integer(8))
          allocate(integer(8)::tmp(this%size_))
       type is(double precision)          
          allocate(double precision::tmp(this%size_))
       type is(tuple_i4_t)
          allocate(tuple_i4_t::tmp(this%size_))
       type is(tuple4_i4_t)
          allocate(tuple4_i4_t::tmp(this%size_))
       type is(struct_curve_t)
          allocate(struct_curve_t::tmp(this%size_))
       type is (nmsh_quad_t)
          allocate(nmsh_quad_t::tmp(this%size_))
       type is (nmsh_hex_t)
          allocate(nmsh_hex_t::tmp(this%size_))
       type is (nmsh_zone_t)
          allocate(nmsh_zone_t::tmp(this%size_))
       type is (nmsh_curve_el_t)
          allocate(nmsh_curve_el_t::tmp(this%size_))
       end select
       select type(tmp)
       type is (integer)
          select type(sdp=>this%data)
          type is (integer)
             tmp(1:this%top_) = sdp
          end select
       type is (integer(8))
          select type(sdp=>this%data)
          type is (integer(8))
             tmp(1:this%top_) = sdp
          end select
       type is (double precision)
          select type(sdp=>this%data)
          type is (double precision)
             tmp(1:this%top_) = sdp
          end select
       type is (tuple_i4_t)
          select type(sdp=>this%data)
          type is (tuple_i4_t)
             tmp(1:this%top_) = sdp
          end select
       type is (tuple4_i4_t)
          select type(sdp=>this%data)
          type is (tuple4_i4_t)
             tmp(1:this%top_) = sdp
          end select
       type is (struct_curve_t)
          select type(sdp=>this%data)
          type is (struct_curve_t)
             tmp(1:this%top_) = sdp
          end select
       type is (nmsh_quad_t)
          select type(sdp=>this%data)
          type is(nmsh_quad_t)
             tmp(1:this%top_) = sdp
          end select
       type is (nmsh_hex_t)
          select type(sdp=>this%data)
          type is(nmsh_hex_t)
             tmp(1:this%top_) = sdp
          end select
       type is (nmsh_zone_t)
          select type(sdp=>this%data)
          type is(nmsh_zone_t)
             tmp(1:this%top_) = sdp
          end select
       type is (nmsh_curve_el_t)
          select type(sdp=>this%data)
          type is(nmsh_curve_el_t)
             tmp(1:this%top_) = sdp
          end select
       end select
       call move_alloc(tmp, this%data)
    end if
    
    this%top_ = this%top_ + 1

    select type(sdp=>this%data)
    type is (integer)
       select type(data)
       type is (integer)
          sdp(this%top_) = data
       end select
    type is (integer(8))
       select type(data)
       type is (integer(8))
          sdp(this%top_) = data
       end select
    type is (double precision)
       select type(data)
       type is (double precision)
          sdp(this%top_) = data
       end select
    type is (tuple_i4_t)
       select type(data)
       type is (tuple_i4_t)
          sdp(this%top_) = data
       end select
    type is (tuple4_i4_t)
       select type(data)
       type is (tuple4_i4_t)
          sdp(this%top_) = data
       end select
    type is (struct_curve_t)
       select type(data)
       type is (struct_curve_t)
          sdp(this%top_) = data
       end select
    type is (nmsh_quad_t)
       select type(data)
       type is (nmsh_quad_t)
          sdp(this%top_) = data
       end select
    type is (nmsh_hex_t)
       select type(data)
       type is (nmsh_hex_t)
          sdp(this%top_) = data
       end select
    type is (nmsh_zone_t)
       select type(data)
       type is (nmsh_zone_t)
          sdp(this%top_) = data
       end select
    type is (nmsh_curve_el_t)
       select type(data)
       type is (nmsh_curve_el_t)
          sdp(this%top_) = data
       end select
    end select
  end subroutine stack_push

  !> Pop an integer of the stack
  function stack_i4_pop(this) result(data)
    class(stack_i4_t), target, intent(inout) :: this
    integer :: data

    select type(sdp=>this%data)
    type is (integer)       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ - 1
  end function stack_i4_pop

  !> Return a pointer to the internal integer array
  function stack_i4_data(this) result(data)
    class(stack_i4_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    integer, pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (integer)       
       data => sdp
    end select
  end function stack_i4_data

  !> Pop an integer*8 of the stack
  function stack_i8_pop(this) result(data)
    class(stack_i8_t), target, intent(inout) :: this
    integer(kind=8) :: data

    select type(sdp=>this%data)
    type is (integer(8))       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ - 1
  end function stack_i8_pop

  !> Return a pointer to the internal integer*8 array
  function stack_i8_data(this) result(data)
    class(stack_i8_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    integer(kind=8), pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (integer(8))       
       data => sdp
    end select
  end function stack_i8_data

  !> Pop a double precision value of the stack
  function stack_r8_pop(this) result(data)
    class(stack_r8_t), target, intent(inout) :: this
    real(kind=dp) :: data
    
    select type (sdp=>this%data)
    type is (double precision)       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ -1
  end function stack_r8_pop

  !> Return a pointer to the internal double precision array 
  function stack_r8_data(this) result(data)
    class(stack_r8_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    real(kind=dp), pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (double precision)       
       data => sdp
    end select
  end function stack_r8_data

  !> Pop an integer 2-tuple of the stack
  function stack_i4t2_pop(this) result(data)
    class(stack_i4t2_t), target, intent(inout) :: this
    type(tuple_i4_t) :: data
    
    select type (sdp=>this%data)
    type is (tuple_i4_t)       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ -1
  end function stack_i4t2_pop

  !> Return a pointer to the interal 2-tuple array
  function stack_i4t2_data(this) result(data)
    class(stack_i4t2_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    type(tuple_i4_t), pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (tuple_i4_t)       
       data => sdp
    end select
  end function stack_i4t2_data

  !> Pop an integer 4-tuple of the stack
  function stack_i4t4_pop(this) result(data)
    class(stack_i4t4_t), target, intent(inout) :: this
    type(tuple4_i4_t) :: data
    
    select type (sdp=>this%data)
    type is (tuple4_i4_t)       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ -1
  end function stack_i4t4_pop

  !> Return a pointer to the internal 4-tuple array
  function stack_i4t4_data(this) result(data)
    class(stack_i4t4_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    type(tuple4_i4_t), pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (tuple4_i4_t)       
       data => sdp
    end select
  end function stack_i4t4_data
 
  !> Pop a curve element of the stack
  function stack_curve_element_pop(this) result(data)
    class(stack_curve_t), target, intent(inout) :: this
    type(struct_curve_t) :: data
    
    select type (sdp=>this%data)
    type is (struct_curve_t)       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ -1
  end function stack_curve_element_pop

  !> Return a pointer to the internal curve element array
  function stack_curve_element_data(this) result(data)
    class(stack_curve_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    type(struct_curve_t), pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (struct_curve_t)       
       data => sdp
    end select
  end function stack_curve_element_data

  !> Pop a Neko quad element of the stack
  function stack_nq_pop(this) result(data)
    class(stack_nq_t), target, intent(inout) :: this
    type(nmsh_quad_t) :: data

    select type (sdp=>this%data)
    type is (nmsh_quad_t)       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ -1
  end function stack_nq_pop

  !> Return a pointer to the internal Neko quad array
  function stack_nq_data(this) result(data)
    class(stack_nq_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    type(nmsh_quad_t), pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (nmsh_quad_t)       
       data => sdp
    end select
  end function stack_nq_data

  !> Pop a Neko hex element of the stack
  function stack_nh_pop(this) result(data)
    class(stack_nh_t), target, intent(inout) :: this
    type(nmsh_hex_t) :: data

    select type (sdp=>this%data)
    type is (nmsh_hex_t)       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ -1
  end function stack_nh_pop

  !> Return a pointer to the internal Neko quad array
  function stack_nh_data(this) result(data)
    class(stack_nh_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    type(nmsh_hex_t), pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (nmsh_hex_t)       
       data => sdp
    end select
  end function stack_nh_data

  !> Pop a Neko zone of the stack
  function stack_nz_pop(this) result(data)
    class(stack_nz_t), target, intent(inout) :: this
    type(nmsh_zone_t) :: data

    select type (sdp=>this%data)
    type is (nmsh_zone_t)       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ -1
  end function stack_nz_pop

  !> Return a pointer to the internal Neko zone array
  function stack_nz_data(this) result(data)
    class(stack_nz_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    type(nmsh_zone_t), pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (nmsh_zone_t)       
       data => sdp
    end select
  end function stack_nz_data

  !> Pop a Neko curve info of the stack
  function stack_nc_pop(this) result(data)
    class(stack_nc_t), target, intent(inout) :: this
    type(nmsh_curve_el_t) :: data

    select type (sdp=>this%data)
    type is (nmsh_curve_el_t)       
       data = sdp(this%top_)
    end select
    this%top_ = this%top_ -1
  end function stack_nc_pop

  !> Return a pointer to the internal Neko curve info array
  function stack_nc_data(this) result(data)
    class(stack_nc_t), target, intent(inout) :: this
    class(*), pointer :: sdp(:)
    type(nmsh_curve_el_t), pointer :: data(:)

    sdp=>this%data
    select type(sdp)
    type is (nmsh_curve_el_t)       
       data => sdp
    end select
  end function stack_nc_data
  
end module stack