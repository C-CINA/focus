/* 
 * @license GNU Public License
 * @author Nikhil Biyani (nikhilbiyani@gmail.com)
 * 
 */

#ifndef MRC_WRITER_HPP
#define	MRC_WRITER_HPP

#include <iostream>
#include "../data_structures/volume_header.hpp"
#include "../data_structures/real_space_data.hpp"

namespace volume_processing_2dx
{
    namespace io
    {
        namespace mrc_writer
        {
            /**
             * Writes a MRC file with the real space data
             * @param file_name
             * @param header
             * @param data
             */
            void write_real(const std::string file_name,
                            const volume_processing_2dx::data_structures::VolumeHeader2dx& header,
                            const volume_processing_2dx::data_structures::RealSpaceData& data);
            
        }
        
    }
    
}

#endif	/* MRC_WRITER_HPP */

