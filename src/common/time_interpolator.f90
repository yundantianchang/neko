! Copyright (c) 2022, The Neko Authors
! All rights reserved.
!
! Redistribution and use in source and binary forms, with or without
! modification, are permitted provided that the following conditions
! are met:
!
!   * Redistributions of source code must retain the above copyright
!     notice, this list of conditions and the following disclaimer.
!
!   * Redistributions in binary form must reproduce the above
!     copyright notice, this list of conditions and the following
!     disclaimer in the documentation and/or other materials provided
!     with the distribution.
!
!   * Neither the name of the authors nor the names of its
!     contributors may be used to endorse or promote products derived
!     from this software without specific prior written permission.
!
! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
! "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
! LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
! FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
! COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
! INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
! BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
! LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
! CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
! LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
! ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
! POSSIBILITY OF SUCH DAMAGE.
!
!> Implements type time_interpolator_t.
module time_interpolator
  use num_types, only : rp
  use field, only : field_t
  use neko_config
  use device_math, only : device_add3s2
  use math, only : add3s2
  use utils, only : neko_error
  use, intrinsic :: iso_c_binding
  implicit none
  private

  !> Provides a tool to perform interpolation in time
  type, public :: time_interpolator_t
     !> Order of the interpolation
     integer :: order
   contains
     !> Initialize object.
     procedure, pass(this) :: init => time_interpolator_init
     !> Destructor
     procedure, pass(this) :: free => time_interpolator_free
     !> Calculate the indicator
     procedure, pass(this) :: interpolate => time_interpolator_interpolate

  end type time_interpolator_t

contains

  !> Constructor
  !! @param order order of the interpolation
  subroutine time_interpolator_init(this, order)
    class(time_interpolator_t), intent(inout) :: this
    integer, intent(in), target :: order

    !> call destructior
    call this%free()

    !> Assign values
    this%order = order

  end subroutine time_interpolator_init


  !> Destructor
  subroutine time_interpolator_free(this)
    class(time_interpolator_t), intent(inout) :: this

  end subroutine time_interpolator_free

  !> Interpolate a field at time t from fields at time t-dt and t+dt
  !! @param t time to get interpolated field
  !! @param f interpolated field
  !! @param t_past time in the past for interpolation
  !! @param f_past field in the past for interpolation
  !! @param t_future time in future for interpolation
  !! @param f_future time in future for interpolation
  subroutine time_interpolator_interpolate(this, t, f, t_past, f_past, t_future, f_future)
    class(time_interpolator_t), intent(inout) :: this
    real(kind=rp), intent(inout) :: t, t_past, t_future
    type(field_t), intent(inout) :: f, f_past, f_future
    real(kind=rp) :: w_past, w_future !Weights for the interpolation
    integer :: n

    if (this%order .eq. 2) then

       n = f%dof%size()
       w_past   = ( t_future - t ) / ( t_future - t_past )
       w_future = ( t - t_past ) / ( t_future - t_past )

       if (NEKO_BCKND_DEVICE .eq. 1) then
          call device_add3s2(f%x_d, f_past%x_d, f_future%x_d, &
        w_past, w_future, n)
       else
          call add3s2(f%x, f_past%x, f_future%x, w_past, w_future, n)
       end if

    else
       call neko_error("Time interpolation of required order is not implemented")
    end if

  end subroutine time_interpolator_interpolate

end module time_interpolator
