/* 
 * @license GNU Public License
 * @author Nikhil Biyani (nikhilbiyani@gmail.com)
 * 
 */

#include <iostream>
#include <math.h>

#include "common_definitions.hpp"
#include "fourier_space_data.hpp"


namespace ds = tdx::data;

ds::FourierSpaceData::FourierSpaceData()
{
    _data = std::map<MillerIndex, DiffractionSpot>();
}

ds::FourierSpaceData::FourierSpaceData(const FourierSpaceData& copy)
{
    reset(copy);
}

ds::FourierSpaceData::~FourierSpaceData(){}

ds::FourierSpaceData::FourierSpaceData(const std::multimap<MillerIndex, DiffractionSpot>& spot_multimap)
{
    _data = std::map<MillerIndex, DiffractionSpot>();
    std::map<MillerIndex, DiffractionSpot> back_projected_map = backproject(spot_multimap);
    _data.insert(back_projected_map.begin(), back_projected_map.end());    
}

void ds::FourierSpaceData::clear()
{
    _data.clear();
}

void ds::FourierSpaceData::reset(const FourierSpaceData& data)
{
    _data.clear();
    _data.insert(data.begin(), data.end());
}

ds::FourierSpaceData& ds::FourierSpaceData::operator=(const FourierSpaceData& rhs)
{
    reset(rhs);
    return *this;
}

ds::FourierSpaceData ds::FourierSpaceData::operator+(const FourierSpaceData& rhs)
{
    FourierSpaceData* new_data = new FourierSpaceData();
    
    //Iterate over all possible miller indices h, k, l in current data
    for(const_iterator ref=this->begin(); ref!=this->end(); ++ref)
    {
        ds::MillerIndex index = (*ref).first;
        ds::Complex current_complex = (*ref).second.value();
        ds::Complex new_complex(current_complex.real(), current_complex.imag());
        
        if(rhs.exists(index.h(), index.k(), index.l()))
        {
            Complex rhs_complex = rhs.complex_at(index.h(), index.k(), index.l());
            new_complex = rhs_complex + current_complex;
        }     
        new_data->set_value_at(index.h(), index.k(), index.l(), new_complex, weight_at(index.h(), index.k(), index.l()) );
    }
    
    //Iterate over all possible miller indices h, k, l in rhs data
    for(const_iterator ref=rhs.begin(); ref!=rhs.end(); ++ref)
    {
        //Assign the current Miller Index to the array
        ds::MillerIndex index = (*ref).first;
        ds::Complex current_complex = (*ref).second.value();

        if( !(new_data->exists(index.h(), index.k(), index.l())) )
        {
            new_data->set_value_at(index.h(), index.k(), index.l(), current_complex, (*ref).second.weight() );
        }
    }
    
    return *new_data;
}

ds::FourierSpaceData ds::FourierSpaceData::operator*(double factor)
{
    FourierSpaceData* data = new FourierSpaceData();
    for(const_iterator ref=this->begin(); ref!=this->end(); ++ref)
    {
        ds::MillerIndex index = (*ref).first;
        Complex currentComplex = (*ref).second.value();
        double current_amp = currentComplex.amplitude();
        currentComplex.set_amplitude(current_amp*factor);
        data->set_value_at(index.h(), index.k(), index.l(), currentComplex, (*ref).second.weight());
    }
    return *data;
}

ds::FourierSpaceData::const_iterator ds::FourierSpaceData::begin() const
{
    return _data.begin();
}

ds::FourierSpaceData::const_iterator ds::FourierSpaceData::end() const
{
    return _data.end();
}

bool ds::FourierSpaceData::exists(int h, int k, int l) const
{
    bool result = true;
    if ( _data.find(MillerIndex(h, k, l)) == _data.end() )
    {
        result = false;
    }
    
    return result; 

}

void ds::FourierSpaceData::set_value_at(int h, int k, int l, Complex value, double weight)
{
    MillerIndex index = MillerIndex(h, k, l);
    //if(h < 0) std::cerr << "\nWARNING: Encountered negative h value, there is a problem somewhere!\n\n";
    _data[index] = DiffractionSpot(value, weight);
}

ds::Complex ds::FourierSpaceData::complex_at(int h, int k, int l) const
{
    ds::Complex value(0.0, 0.0);
    if(exists(h,k,l))
    {
        value = _data.at(MillerIndex(h, k, l)).value();
    }
    return value;
}

double ds::FourierSpaceData::weight_at(int h, int k, int l) const
{
    double weight = 0.0;
    if(exists(h,k,l))
    {
        weight = _data.at(MillerIndex(h, k, l)).weight();
    }
    return weight;
}

double ds::FourierSpaceData::intensity_sum() const
{
    double sum = 0.0;
    for(const_iterator ref=this->begin(); ref!=this->end(); ++ref)
    {
        sum += (*ref).second.intensity();
    }
    
    return sum;
}

int ds::FourierSpaceData::spots() const
{
    return _data.size();
}

double ds::FourierSpaceData::max_amplitude() const
{
    double max = 0;
    for(const_iterator ref=this->begin(); ref!=this->end(); ++ref)
    {
        //Assign the current Miller Index to the array
        double amplitude = (*ref).second.amplitude();
        if(max < amplitude) max = amplitude;
    }
    
    return max;
}

std::map<ds::MillerIndex, ds::DiffractionSpot> ds::FourierSpaceData::backproject(const std::multimap<MillerIndex, DiffractionSpot>& spot_multimap) const
{
    std::map<MillerIndex, DiffractionSpot> map;
    bool initialized = false;
    
    ds::MillerIndex current_index;
    std::list<ds::DiffractionSpot> current_spots;
    
    for(std::map<ds::MillerIndex, ds::DiffractionSpot>::const_iterator spot_itr=spot_multimap.begin(); 
            spot_itr!=spot_multimap.end(); ++spot_itr)
    {
        // Initialize for the start
        if(!(initialized))
        {
            current_index = (*spot_itr).first;
            initialized = true;
        }
        
        // Average and insert accumulated spots
        if(!(current_index == (*spot_itr).first))
        {
            ds::DiffractionSpot avg_spot(current_spots);
            map.insert(std::pair<MillerIndex, DiffractionSpot>(current_index, avg_spot));
            current_spots.clear();
        }
        
        //Accumulate the spots in a list
        current_spots.push_back((*spot_itr).second);
        current_index = (*spot_itr).first;
        
    }
    
    //insert the final reflection
    ds::DiffractionSpot avg_spot(current_spots);
    map.insert(std::pair<MillerIndex, DiffractionSpot>(current_index, avg_spot));
    
    return map;
}

void ds::FourierSpaceData::scale_amplitudes(double factor)
{
    *this = (*this)*factor;
}

fftw_complex* ds::FourierSpaceData::fftw_data(int fx, int fy, int fz) const
{
    fftw_complex* fftw_data = fftw_alloc_complex(fx*fy*fz);

    int size = fx*fy*fz;

    //Zero initialization
    for(int i=0; i<fx*fy*fz; i++)
    {
        ((fftw_complex*)fftw_data)[i][0] = 0.0;
        ((fftw_complex*)fftw_data)[i][1] = 0.0;
    }
    
    //Iterate over all possible miller indices h, k, l
    for(const_iterator ref=this->begin(); ref!=this->end(); ++ref)
    {

        //Assign the current Miller Index to the array
        ds::MillerIndex currentHKL = (*ref).first;
        Complex currentComplex = (*ref).second.value();
        
        // Fill in this spot
        if(currentHKL.h() >= 0){
            int idx = currentHKL.h();
            int idy = currentHKL.k();
            int idz = currentHKL.l();
            if(idy < 0) idy = idy + fy;
            if(idz < 0) idz = idz + fz;
            
            int memory_id = idx + (idy*fx) + (idz*fy*fx);  
            if(memory_id >= size)
            {
                std::cerr << "Oops! This reflection exceeds limits!! Leaving it!\n";
                std::cerr << "Miller index found: " << currentHKL.to_string() << " and HKL Limit: +/-(" << fx-1 << ", " << fy/2 << ", " << fz/2 << ")\n";
            }
            else
            {
                ((fftw_complex*)fftw_data)[memory_id][0] = currentComplex.real();
                ((fftw_complex*)fftw_data)[memory_id][1] = currentComplex.imag();
            }
        }
    }
    
    return fftw_data;

}

void ds::FourierSpaceData::reset_data_from_fftw(int fx, int fy, int fz, fftw_complex* complex_data)
{
    this->clear();
    
    int h_max = fx - 1;
    int k_max = (int) fy/2;
    int l_max = (int) fz/2;
           

    //Loop over all possible indices and set their values
    for(int ix=0; ix < fx; ix++){
        for(int iy=0; iy < fy; iy++){
            for(int iz=0; iz<fz ; iz++){
                int memory_id = ix + (iy*fx) + (iz*fy*fx); 
                double real = ((fftw_complex*)complex_data)[memory_id][0];
                double imag = ((fftw_complex*)complex_data)[memory_id][1];

                //Assign the current miller index
                Complex currentComplex(real, imag);
                
                int h = ix;
                int k = iy;
                int l = iz;
                
                if(k > k_max) k = k - fy;
                if(l > l_max) l = l - fz;

                MillerIndex currentHKL(h, k, l);

                if(h >= 0 && h <= h_max &&  currentComplex.amplitude() > 0.0001){
                    this->set_value_at(currentHKL.h(), currentHKL.k(), currentHKL.l(), currentComplex, 1.0);
                }
            }
        }
    }
}

void ds::FourierSpaceData::replace_reflections(const FourierSpaceData& input, double cone_angle, double replacement_amplitude_cutoff)
{   
    std::cout << "Replacing reflection and keeping the new ones in a cone of angle: " << cone_angle <<"\n";
    
    FourierSpaceData new_data;
    
    if(cone_angle < 0.0 || cone_angle > 90)
    {
        std::cerr << "Error: Bad value encountered in cone_angle: " << std::to_string(cone_angle) << " (min 0 and max 90)\n";
        return;
    }
    
    double cone_angle_rad = double(cone_angle)*M_PI/180;

    //Iterate over all possible miller indices h, k, l in input data 
    for(const_iterator ref=input.begin(); ref!=input.end(); ++ref)
    {
        //Assign the current Miller Index to the array
        ds::MillerIndex index = (*ref).first;
        ds::Complex current_complex = (*ref).second.value();

        if(current_complex.amplitude() > replacement_amplitude_cutoff)
        {
            new_data.set_value_at(index.h(), index.k(), index.l(), current_complex, (*ref).second.weight() );
        }
    }
    
    //Iterate over all the current reflections
    for(const_iterator ref=this->begin(); ref!=this->end(); ++ref)
    {
        //Assign the current Miller Index to the array
        ds::MillerIndex index = (*ref).first;
        ds::Complex current_complex = (*ref).second.value();
        double radius = std::abs(index.l()*tan(cone_angle_rad));
        double distance = sqrt(index.h()*index.h() + index.k()*index.k());
        if(current_complex.amplitude() > replacement_amplitude_cutoff && !new_data.exists(index.h(), index.k(), index.l()) && distance < radius)
        {
            new_data.set_value_at(index.h(), index.k(), index.l(), current_complex, (*ref).second.weight() );
        }
    }
    
    std::cout << "Current spots " << spots() << " were replaced with: " << new_data.spots() << " (Input had " << input.spots() << " spots)\n";
    reset(new_data);
}

void ds::FourierSpaceData::change_amplitudes(const FourierSpaceData& input, double replacement_amplitude_cutoff)
{   
    //Iterate over all possible miller indices h, k, l in input data
    for(const_iterator ref=input.begin(); ref!=input.end(); ++ref)
    {
        //Assign the current Miller Index to the array
        ds::MillerIndex index = (*ref).first;
        double current_amp = (*ref).second.value().amplitude();

        if( exists(index.h(), index.k(), index.l()) && current_amp > replacement_amplitude_cutoff)
        {
            ds::Complex current_complex = complex_at(index.h(), index.k(), index.l());
            current_complex.set_amplitude(current_amp);
            double current_weight = weight_at(index.h(), index.k(), index.l());
            set_value_at(index.h(), index.k(), index.l(), current_complex, current_weight );
        }
    } 
}

ds::FourierSpaceData ds::FourierSpaceData::inverted_data(int direction) const
{
    if(direction == 0 || direction == 1  || direction == 2 || direction == 3)
    {
        //Iterate over all possible miller indices h, k, l
        FourierSpaceData new_data;
        for(const_iterator ref=this->begin(); ref!=this->end(); ++ref)
        {
            //Assign the current Miller Index to the array
            ds::MillerIndex currentHKL = (*ref).first;
            double currentAmp = (*ref).second.value().amplitude();
            double currentPhase = (*ref).second.value().phase();
            int h = currentHKL.h();
            int k = currentHKL.k();
            int l = currentHKL.l();
            if(direction == 1 || direction == 0) h = -1*h;
            if(direction == 2 || direction == 0) k = -1*k;
            if(direction == 3 || direction == 0) l = -1*l;
            
            //Get Friedel spot for negative h
            if(h < 0) {h = -1*h; k=-1*k; l=-1*l; currentPhase = currentPhase*-1;} 
            
            ds::Complex newValue = ds::Complex(currentAmp*cos(currentPhase), currentAmp*sin(currentPhase));
            new_data.set_value_at(h, k, l, newValue, (*ref).second.weight());
        }
        
        return new_data;
    }
    else
    {
        std::cerr << "ERROR: Encountered bad value of direction (" << direction << ") while inverting data in Fourier space (Possible values 0(for all), 1(for x), 2(for y), 3(for z))\n";
        std::cerr << "ERROR: NOT INVERTING\n";
        return *this;
    }
}

void ds::FourierSpaceData::spread_data()
{
    std::cout << "Spreading the data in Fourier space.. \n";
    std::cout << "Current spots: " << spots() << "\n";
    std::multimap<MillerIndex, DiffractionSpot> spreaded_raw;
    for(const_iterator ref=this->begin(); ref!=this->end(); ++ref)
    {
        MillerIndex index_in = (*ref).first;
        DiffractionSpot spot_in = (*ref).second;
        
        //Insert this spot
        spreaded_raw.insert(MillerIndexDiffSpotPair(index_in, spot_in));
        
        //Spread this spot to neighbors if not present
        for(int ih=-2; ih<=2; ih++)
        {
            for(int ik=-2; ik<=2; ik++)
            {
                for(int il=-2; il<=2; il++)
                {
                    MillerIndex new_index = MillerIndex(index_in.h()+ih, index_in.k()+ik, index_in.l()+il);
                    if(!exists(new_index.h(), new_index.k(), new_index.l()))
                    {
                        double distance_square = il*il + ik*ik + ih*ih;
                        
                        //1.6 is to make the integral of exponential 1
                        double weight = exp(-1.6*distance_square);
                        spreaded_raw.insert(MillerIndexDiffSpotPair(new_index, spot_in*weight));
                    }
                }
            }
        }
        
    }
    
    std::map<MillerIndex, DiffractionSpot> spreaded_map = backproject(spreaded_raw);
    
    _data.clear();
    _data.insert(spreaded_map.begin(), spreaded_map.end());
    
    std::cout << "Spots after spread: " << spots() << "\n";
    
}

ds::FourierSpaceData ds::FourierSpaceData::get_full_fourier() const
{
    
    FourierSpaceData full_data;
    for(const_iterator ref=this->begin(); ref!=this->end(); ++ref)
    {
        //Assign the current Miller Index to the array
        ds::MillerIndex currentHKL = (*ref).first;
        ds::Complex currentComplex = (*ref).second.value();
        
        ds::MillerIndex friedelHKL = currentHKL.FriedelSpot();
        ds::Complex friedelComplex = currentComplex;
        friedelComplex.set_phase(-1*currentComplex.phase());
        
        full_data.set_value_at(currentHKL.h(), currentHKL.k(), currentHKL.l(), currentComplex, (*ref).second.weight());
        full_data.set_value_at(friedelHKL.h(), friedelHKL.k(), friedelHKL.l(), friedelComplex, (*ref).second.weight());
    }
    
    return full_data;
    
}