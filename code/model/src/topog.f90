subroutine topog 
  !     ----------------                                                  
  USE header
  !     dy is the y grid spacing in m                                     
  !     creates the bottom topography                                     
  !     fits a spline to the described topog and computed Ddx(i)          
      integer i,j,NJnew,NJ2,jj,nfac,nfacm1,jtemp,inc 
      parameter (nfac=4) 
      parameter (nfacm1= nfac-1) 
      parameter (NJnew=nfac*NJ) 
      parameter (NJ2= NJnew+2*nfac) 
      REAL(kind=rc_kind) :: dynew,dep,seval,LbyD,DLinv 
      REAL(kind=rc_kind) :: ynew(-nfacm1:NJnew+nfac),                        &
     &     dnew(-nfacm1:NJnew+nfac),bd1(-nfacm1:NJnew+nfac),            &
     &     cd1(-nfacm1:NJnew+nfac),dd1(-nfacm1:NJnew+nfac)              
                                                                        
      dynew= dy/float(nfac) 
      LbyD= LEN/DL 
      DLinv=1.d0/DL 
      write(6,*) 'dynew = ', dynew 
                                                                        
!     ynew is in km                                                     
      ynew(-nfacm1)= -(0.5+ float(nfacm1)) *dynew*1.d-3 
      do j=-nfacm1+1,NJnew+nfac 
         ynew(j)= ynew(j-1) +dynew*1.d-3 
!-         write(6,*) j,ynew(j)                                         
      end do 
                                                                        
      do j=-nfac,NJnew+nfac 
!==         goto 103                                                    
!=         goto 104                                                     
!     Gawarkeiwicz topography  (c- shifted S by 40km)                   
         if (ynew(j).lt.50.) then 
!-         if (ynew(j).lt.10.) then                                     
!     continental shelf                                                 
            dep= 50. + 2.*ynew(j) 
!-            dep= 130. + 2.*ynew(j)                                    
         elseif (ynew(j).lt.60.) then 
!-         elseif (ynew(j).lt.20.) then                                 
            dep= 160. + 1.5*(ynew(j)-50.)**2 -0.1*(ynew(j)-60.)**2 
!-            dep= 160. + 1.5*(ynew(j)-10.)**2 -0.1*(ynew(j)-20.)**2    
!c         elseif (ynew(j).lt.100.) then                                
         elseif (ynew(j).lt.80.) then 
!-         elseif (ynew(j).lt.60.) then                                 
            dep= 310. +30*(ynew(j)-60.) 
!-            dep= 310. +30*(ynew(j)-20.)                               
!c         elseif (ynew(j).lt.110.) then                                
         elseif (ynew(j).lt.90.) then 
!-         elseif (ynew(j).lt.70.) then                                 
            dep= 1060. -1.5*(ynew(j)-90.)**2 
!c            dep= 1660. -1.5*(ynew(j)-110.)**2                         
!-            dep= 1660. -1.5*(ynew(j)-70.)**2                          
         else 
!c            dep= 1660.                                                
            dep= 1060.d0 
         end if 
!-         write(6,*) j,dep                                             
         goto 105 
!    -------------------                                                
  103    if (ynew(j).le.34.5) then 
!     continental shelf                                                 
            dep= 50. + 2.*ynew(j) 
         elseif (ynew(j).le.55.0) then 
!     continental slope                                                 
            dep= 110. + 30.*(ynew(j)-31.5) 
         else 
            dep= 110. + 30.*(55.-31.5) 
         end if 
!     -----------                                                       
! 104     dep= 1600.d0                                                  
104      dep= 50. + 2.*ynew(j)   !linear slope 
! 104     dep= 320. + 20.*ynew(j)   -linear slope                       
!= 104     dep= 400. + 20.*ynew(j)   -linear slope                      
  105    dnew(j)= dep 
      end do 
!     D(i,j) should be non-dim by DL and is negative                    
                                                                        
                                                                        
      call spline (NJ2,ynew,dnew,bd1,cd1,dd1) 
                                                                        
      do j=0,NJ+1 
         dep= seval(NJ2,yc(j),ynew,dnew,bd1,cd1,dd1) 
!-         write(6,*) j,yc(j),dep                                       
                                                                        
         do jj=-nfacm1,NJnew+nfac 
            if ((yc(j).lt.ynew(jj+1)).and.(yc(j).ge.ynew(jj))) then 
               ytemp= yc(j)-ynew(jj) 
!==               deriv= bd1(jj) +2.d0*cd1(jj)*ytemp                    
!==     &              +3.d0*dd1(jj)*ytemp*ytemp                        
!=     finite diff form                                                 
               jtemp= nfac*j 
               inc= nfac/2 
               if (j.ne.NJ+1) then 
                  deriv= (dnew(jtemp+inc) - dnew(jtemp-inc))/           &
     &                 (ynew(jtemp+inc) -ynew(jtemp-inc))               
               else 
                  deriv= (dnew(jtemp) - dnew(jtemp-inc))/               &
     &                 (ynew(jtemp) -ynew(jtemp-inc))                   
               end if 
               do i=0,NI+1 
                  D(i,j)= -dep*DLinv 
                  Ddy(i,j)= deriv*LbyD*1.d-3 
                  Ddx(i,j)= 0.d0 
!     multiplication by (L/D)*1.d-3 takes care of converting from km to 
!     and non-dimensionalizing                                          
!                 if (i.eq.0) write(101,*) D(i,j)                       
               end do 
               goto 101 
            endif 
         end do 
         write(6,*) 'some prob in topog' 
         write(6,*) yc(j), jj 
         stop 
  101 end do 
                                                                        
!     Ddy = b(i) + 2*c(i) (x-x(i)) + 3* d(i) (x-x(i))^2                 
                                                                        
      open (unit=70, file=TRIM(dirout)//'Ddxdy.dat') 
      do j=0,NJ+1 
         write(70,*) 'j= ',j 
         do i=0,NI+1 
            write(70,*) D(i,j),Ddx(i,j),Ddy(i,j) 
        end do 
      end do 
      close(70) 
                                                                        
      return 
                                                                        
      do i=0,NI+1 
         y= -1.5*dy*1.d-3 
         do j=0,NJ+1 
            y= y +dy*1.d-3 
            if (y.le.34.5) then 
!     continental shelf                                                 
               dep= 50. + 2.*y 
            elseif (y.le.55.0) then 
!     continental slope                                                 
               dep= 110. + 30.*(y-31.5) 
            else 
               dep= 110. + 30.*(55.-31.5) 
            end if 
            D(i,j)= -dep*DLinv 
            if (i.eq.0) write(102,*)  D(i,j) 
!            write(6,*) 'y,dep',y,dep,ydv(i,j)                          
         end do 
      end do 
                                                                        
      stop 
      return 
      END                                           
