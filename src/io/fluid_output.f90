!> Defines an output for a fluid
module fluid_output
  use fluid_method
  use output
  implicit none
  private

  !> Fluid output
  type, public, extends(output_t) :: fluid_output_t
     class(fluid_scheme_t), pointer :: fluid
   contains
     procedure, pass(this) :: sample => fluid_output_sample
  end type fluid_output_t

  interface fluid_output_t
     module procedure fluid_output_init
  end interface fluid_output_t

contains

  function fluid_output_init(fluid, name, path) result(this)
    class(fluid_scheme_t), intent(in), target :: fluid
    character(len=*), intent(in), optional :: name
    character(len=*), intent(in), optional :: path
    type(fluid_output_t) :: this
    character(len=1024) :: fname

    if (present(name) .and. present(path)) then
       fname = trim(path) // trim(name) // '.fld'
    else if (present(name)) then
       fname = trim(name) // '.fld'
    else if (present(path)) then
       fname = trim(path) // 'field.fld'
    else       
       fname = 'field.fld'
    end if
    
    call output_init(this, fname)    
    this%fluid => fluid
  end function fluid_output_init

  !> Sample a fluid solution at time @a t
  subroutine fluid_output_sample(this, t)
    class(fluid_output_t), intent(inout) :: this
    real(kind=rp), intent(in) :: t
    call this%file_%write(this%fluid, t)

  end subroutine fluid_output_sample
  
end module fluid_output
